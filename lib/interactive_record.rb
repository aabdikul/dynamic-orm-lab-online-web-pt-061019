require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "PRAGMA table_info('#{self.table_name}')"
    DB[:conn].results_as_hash = true
    DB[:conn].execute(sql).map {|column| column["name"]}.compact
  end

  def initialize(hash_in = nil)
    if !hash_in.nil?
      hash_in.each {|keys,values| send("#{keys}=",values)}
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.map {|col| "'#{send(col)}'"}.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{self.values_for_insert})
      SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = ?
      SQL
    DB[:conn].results_as_hash = true
    DB[:conn].execute(sql,name)
  end

  def self.find_by(hash_in)
    value = hash_in.values.first
    formatted_value = value.class == Fixnum ? value : "'#{value}'"
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{hash_in.keys.first} = #{formatted_value}
      SQL
    DB[:conn].results_as_hash = true
    DB[:conn].execute(sql)
    binding.pry
  end

end
