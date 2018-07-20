defmodule Pow.Test.Phoenix.MailerMock do
  use Pow.Phoenix.Mailer

  def cast(email), do: email
  def process(email) do
    send self(), {:mail_mock, email}
  end
end
