class RenameYnabConnectionBudgetToPlan < ActiveRecord::Migration[8.1]
  def change
    rename_column :ynab_connections, :budget_id, :plan_id
    rename_column :ynab_connections, :budget_name, :plan_name
    add_column :ynab_connections, :account_name, :string
  end
end
