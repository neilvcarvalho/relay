class ProcessNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id, account_id: nil)
    notification = Notification.find(notification_id)
    notification.mark_processing!

    connection = notification.user.ynab_connection
    unless connection
      notification.mark_failed!("No YNAB connection configured for this user")
      raise "No YNAB connection configured for user #{notification.user_id}"
    end

    result = BankingNotificationAgent.new.call(notification.text)

    YnabClient.new(connection).create_transaction(
      account_id: account_id || connection.account_id,
      amount: result.amount,
      payee_name: result.payee_name,
      memo: result.memo,
      date: result.date
    )

    notification.mark_completed!
  rescue BankingNotificationAgent::AgentError, YnabClient::Error => e
    notification&.mark_failed!("#{e.class}: #{e.message}")
    raise
  end
end
