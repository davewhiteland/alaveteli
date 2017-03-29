# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'net/pop'

describe AlaveteliMailPoller do
  let(:mockpop3){ MockPOP3.new }
  let(:poller){ AlaveteliMailPoller.new }

  before do
    allow(Net::POP3).to receive(:new).and_return(mockpop3)
  end

  describe '#poll_for_incoming' do

    it 'starts and ends a session with the POP server' do
      expect(MockPOP3).not_to be_started
      poller.poll_for_incoming
      expect(MockPOP3).not_to be_started
    end

    context 'if there is no mail on the POP server' do
      let(:mockpop3){ MockPOP3.new(0) }

      it 'returns false' do
        expect(poller.poll_for_incoming).to be false
      end

    end

    context 'if there is mail on the POP server' do
      let(:mockpop3){ MockPOP3.new(1) }

      it 'returns true' do
        expect(poller.poll_for_incoming).to be true
      end

      it 'sends the mail to RequestMailer.receive' do
        expect(RequestMailer).to receive(:receive).with(mockpop3.mails.first.pop)
        poller.poll_for_incoming
      end

      it 'deletes the mail' do
        poller.poll_for_incoming
        expect(mockpop3.mails.first.deleted?).to be true
      end

      context 'if there is an error getting the unique ID of a mail' do

        before do
          allow(mockpop3.mails.first).
            to receive(:unique_id).
              and_raise(Net::POPError.new("Error code"))
        end

        it 'sends an exception notification' do
          poller.poll_for_incoming
          notification =  ActionMailer::Base.deliveries.first
          expect(notification.subject).
            to eq('[ERROR] (Net::POPError) "Error code"')
        end

      end

      context 'if there is an error getting the text of a mail' do

        before do
          allow(mockpop3.mails.first).
            to receive(:pop).
              and_raise(Net::POPError.new("Error code"))
        end

        it 'sends an exception notification' do
          poller.poll_for_incoming
          notification =  ActionMailer::Base.deliveries.first
          expect(notification.subject).
            to eq('[ERROR] (Net::POPError) "Error code"')
        end

        it 'stores the unique ID with a time of 30 minutes from now' do
          poller.poll_for_incoming
          errors = IncomingMessageError.
                     where(unique_id: mockpop3.mails.first.unique_id)
          expect(errors.size).to eq(1)
          incoming_message_error = errors.first
          expect(incoming_message_error.retry_at).
            to be_within(5.seconds).of(Time.zone.now + 30.minutes)
        end

      end

      context 'if there is an error receiving the mail' do

        before do
          allow(RequestMailer).to receive(:receive).
            with(mockpop3.mails.first.pop).
              and_raise(ActiveRecord::StatementInvalid.new("Deadlock"))
        end

        it 'stores the unique ID with a retry time of 30 minutes from now' do
          poller.poll_for_incoming
          errors = IncomingMessageError.
                     where(unique_id: mockpop3.mails.first.unique_id)
          expect(errors.size).to eq(1)
          incoming_message_error = errors.first
          expect(incoming_message_error.retry_at).
            to be_within(5.seconds).of(Time.zone.now + 30.minutes)
        end

        it 'sends an exception notification' do
          poller.poll_for_incoming
          notification =  ActionMailer::Base.deliveries.first
          expect(notification.subject).
            to eq('[ERROR] (ActiveRecord::StatementInvalid) "Deadlock"')
        end

      end

      context 'if there is an error deleting the mail' do

        before do
          allow(mockpop3.mails.first).
            to receive(:delete).
              and_raise(Net::POPError.new("Error code"))
        end

        it 'stores the unique ID with no retry time' do
          poller.poll_for_incoming
          errors = IncomingMessageError.
                     where(unique_id: mockpop3.mails.first.unique_id)
          expect(errors.size).to eq(1)
          incoming_message_error = errors.first
          expect(incoming_message_error.retry_at).
            to be nil
        end

        it 'sends the response notification and an exception notification' do
          poller.poll_for_incoming
          response_notification =  ActionMailer::Base.deliveries.first
          expect(response_notification.subject).
            to eq('New response to your FOI request - Holding pen')
          exception_notification =  ActionMailer::Base.deliveries.second
          expect(exception_notification.subject).
            to eq('[ERROR] (Net::POPError) "Error code"')
        end

      end

      context 'if mail has previously failed' do
        let(:poller){ AlaveteliMailPoller.new }

        context 'and the mail has no retry time' do

          before do
            IncomingMessageError.create!(unique_id: mockpop3.mails.first.unique_id)
          end

          it 'does not send it to RequestMailer.receive' do
            expect(RequestMailer).not_to receive(:receive)
            poller.poll_for_incoming
          end

        end

        context 'and the mail has not reached its retry time' do

          before do
            IncomingMessageError.create!(unique_id: mockpop3.mails.first.unique_id,
                                         retry_at: Time.now + 30.minutes)
          end

          it 'does not send it to RequestMailer.receive' do
            expect(RequestMailer).not_to receive(:receive)
            poller.poll_for_incoming
          end

        end

        context 'and the mail has reached its retry time' do

          before do
            IncomingMessageError.create!(unique_id: mockpop3.mails.first.unique_id,
                                         retry_at: Time.now - 30.minutes)
          end

          it 'sends it to RequestMailer.receive' do
            expect(RequestMailer).to receive(:receive).
              with mockpop3.mails.first.pop
            poller.poll_for_incoming
          end
        end
      end
    end
  end
end
