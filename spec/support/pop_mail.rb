class MockPopMail
  def initialize(rfc2822, number)
    @rfc2822 = rfc2822
    @number = number
    @deleted = false
  end

  def pop
    @rfc2822
  end

  def number
    @number
  end

  def to_s
    "#{number}: #{pop}"
  end

  def delete
    @deleted = true
  end

  def deleted?
    @deleted
  end

  def unique_id
    @number.to_s
  end
end

class MockPOP3
  @@start = false

  def initialize(number_of_mails = 20)
    @@popmails = []
    number_of_mails.times do |i|
      # "test00", "test01", "test02", ..., "test19"
      @@popmails << MockPopMail.new("test#{i.to_s.rjust(2, '0')}", i)
    end
  end

  def self.popmails
    @@popmails.clone
  end

  def each_mail(*args)
    @@popmails.each do |popmail|
      yield popmail
    end
  end

  def mails(*args)
    @@popmails.clone
  end

  def start(*args)
    @@start = true
    block_given? ? yield(self) : self
  end

  def enable_ssl(*args)
    true
  end

  def started?
    @@start == true
  end

  def self.started?
    @@start == true
  end

  def reset
  end

  def finish
    @@start = false
  end

  def delete_all
    @@popmails = []
  end
end
