$months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
$payee_list = {}
$monthly_payments = {}
$time = Time.new
$ref_year = $time.year

  def create_file
    #creating external files if they don't exist already
    require 'yaml'
    unless File::exist?("Payee_data.yml")
      File.new("Payee_data.yml", "w")
    end
    unless File::exist?("#{$ref_year}_data.yml")
      File.new("#{$ref_year}_data.yml", "w")
    end
    eval_payees
  end

  def eval_payees
    #hashes loaded from empty YAML files will return false, so they must be reset to some value
    load_payees
    if $payee_list == false
      $payee_list = {}
      initiate
    else
      initiate
    end
  end

  def initiate
    #creating a payment table for monthly payments hash when YAML file is empty
    load_monthly_payments
    if $monthly_payments == false
      payments_table = Hash.new
      12.times do
        for month in $months
          payments_table["#{month}"] = {}
        end
      end
      months_data = File.open("#{$ref_year}_data.yml", "w")
      months_data.puts payments_table.to_yaml
      months_data.close
      load_monthly_payments
      sort_by_month
    else
      load_monthly_payments
      sort_by_month
    end
  end

  def sort_by_month
    #storing current payments under the current month in the payments list
    current_month = $months[($time.month) -1]
    $monthly_payments.each do |month_name|
      if month_name = current_month
        unless $monthly_payments["#{month_name}"] == {}
        $monthly_payments["#{month_name}"] = $payee_list
        else
          #reseting the amounts for each payee to 0 when writing to an empty month
          #( = reseting payees to 0 if the month has changed)
          reset_hash = Hash.new
          $payee_list.each do |payee, amount|
            reset_hash["#{payee}"] = 0.00
          end
          $payee_list = {}
          $payee_list = reset_hash
          $monthly_payments["#{month_name}"] = $payee_list
        end
      else
        next
      end
    end
    save_data
  end

  def write_to_file
    #storing main variables in external files
    payees_data = File.open("Payee_data.yml", "w")
    payees_data.puts $payee_list.to_yaml
    payees_data.close

    months_data = File.open("#{$ref_year}_data.yml", "w")
    months_data.puts $monthly_payments.to_yaml
    months_data.close
  end

  def load_payees
    payees_info = YAML.load("Payee_data.yml", "r")
    payees_info.gsub!(/^--- \!.*$/,'')
    $payee_list = YAML.load_file(payees_info)
  end

  def load_monthly_payments
    months_info = YAML.load("#{$ref_year}_data.yml", "r")
    months_info.gsub!(/^--- \!.*$/,'')
    $monthly_payments = YAML.load_file(months_info)
  end

  def add_new_payee
    puts " "
    puts "ENTER THE NAME FOR THE PAYEE: "
    print "> "
    name = $stdin.gets.chomp.upcase.to_s.gsub(" ", "_")
    verify_empty_input(name)
    puts " "
    puts "'#{name}' WILL BE ADDED TO YOUR PAYEES LIST"
    puts "CONTINUE (y/n)?"
    puts "> "
    if $stdin.gets.chomp.downcase.to_s == "y"
      #verifying payee is not already on the list, then adding it
      unless $payee_list.has_key?("#{name}")
        payee_hash = Hash.new
        payee_hash["#{name}"] = 0.00
        $payee_list.merge!(payee_hash)
        sort_payees
        puts " "
        puts "PAYEE SUCCESSFULLY ADDED TO YOUR LIST"
        puts " "
        $payee_list.each do |payee, amount|
          if payee == "#{name}"
            puts "#{payee}: #{amount}"
          else
            next
          end
        end
      sort_by_month
      puts " "
      puts "WOULD YOU LIKE TO ADD ANOTHER PAYEE (y/n)?"
      puts "> "
      answer = $stdin.gets.chomp.downcase
      if answer == "y"
        add_new_payee
      elsif answer == "n"
        option
      else
        puts " "
        puts "PLEASE ENTER 'y' or 'n'..."
      end
      else
      puts " "
      puts "THIS PAYEE ALREADY EXISTS"
      option
      end
    else
      puts " "
      puts "PAYEE NOT ADDED"
      option
    end
  end

  def add_new_payment
    puts " "
    puts "ENTER THE NAME OF THE PAYEE: "
    puts "> "
    name = $stdin.gets.chomp.upcase.to_s.gsub(" ", "_")
    verify_empty_input(name)
    #verifying the payee already exists
    unless $payee_list.has_key?("#{name}")
      puts " "
      puts "'#{name}' IS NOT ON THE LIST"
      puts " "
      puts "WOULD YOU LIKE TO ADD THIS PAYEE NOW (y/n)?"
      puts "> "
      answer = $stdin.gets.chomp.downcase
      if answer == "y"
        add_new_payee
      elsif answer == "n"
        option
      else
        puts "PLEASE ENTER 'y' OR 'n'..."
      end
    else
      puts " "
      puts "ENTER THE AMOUNT OF THE PAYMENT: "
      puts "> "
      input = $stdin.gets.chomp
      def is_numeric?
        true if Float(self) rescue false
      end
      #verifying the input is a number
      if input.is_numeric?
        amount = Float(input)
      else
        puts " "
        puts "PLEASE ENTER A NUMBER"
        option
      end
      #adding the new payment
      $payee_list.each do |payee, value|
        if payee == "#{name}"
          $payee_list["#{name}"] = value + amount
        else
          next
        end
      end
      puts " "
      puts "AMOUNT SUCCESSFULLY UPDATED"
      view_expenses
    end
    sort_by_month
    puts " "
    puts "WOULD YOU LIKE TO ADD ANOTHER PAYMENT (y/n)?"
    puts "> "
    answer = $stdin.gets.chomp.downcase
    if answer == "y"
      add_new_payment
    elsif answer == "n"
      option
    else
      puts " "
      puts "PLEASE ENTER 'y' OR 'n'..."
    end
  end

  def view_expenses
    puts " "
    #verifying there are payees on the list
    if $payee_list.empty? == true
      puts "THERE ARE NO PAYEES CURRENTLY ON YOUR LIST"
      puts " "
      puts "WOULD YOU LIKE TO ADD A NEW PAYEE NOW (y/n)?"
      puts "> "
      answer = $stdin.gets.chomp.downcase
      if answer == "y"
        add_new_payee
      elsif answer == "n"
      option
      else
        puts " "
        puts "PLEASE ENTER 'y' OR 'n'..."
      end
    else
      #printing the amount for each payee, and the total (current month only)
      current_month = $months[($time.month) -1]
      puts "#{current_month}"
      puts "-" * current_month.length
      puts " "
      @total = 0.00
      $payee_list.each do |payee, amount|
        puts "#{payee}: #{amount}"
        @total += $payee_list["#{payee}"]
      end
      puts " "
      @total = @total.round(2)
      puts "TOTAL: #{@total}"
    end
  end

  def view_monthly_totals
    puts " "
    puts "WOULD YOU LIKE TO SEE A SPECIFIC MONTH (y/n)?"
    puts "> "
    answer = $stdin.gets.chomp.downcase
    if answer == "y"
      #showing a specific month
      puts " "
      puts "WHAT MONTH WOULD YOU LIKE TO SEE?"
      puts "> "
      required_month = $stdin.gets.chomp.upcase
      verify_empty_input(required_month)
      #verifying the name of the month is writen correctly
      unless $months.include?("#{required_month}")
        puts " "
        puts "PLEASE ENTER THE NAME OF THE MONTH CORRECTLY"
        view_monthly_totals
      else
        #verifying there are payments to show for the required month
        $monthly_payments.each do |month, payments|
          if month == required_month
            puts " "
            puts "#{month}"
            puts "-" * month.length
            if payments.empty? == true
              puts " "
              puts "THERE ARE NO PAYMENTS TO SHOW FOR THIS MONTH"
            else
              #printing the amount for each payee, and the total for the required month
              puts " "
              @total_in_month = 0.00
              $monthly_payments["#{required_month}"].each do |payee, amount|
                puts "#{payee}: #{amount}"
                @total_in_month += amount
              end
              puts " "
              @total_in_month = @total_in_month.round(2)
              puts "TOTAL PAYED: #{@total_in_month}"
            end
          else
            next
          end
        end
      end
      puts " "
      puts "WOULD YOU LIKE TO SEE ANOTHER MONTH (y/n)?"
      puts "> "
      answer = $stdin.gets.chomp.downcase
      if answer == "y"
        view_monthly_totals
      elsif answer == "n"
        option
      else
        puts " "
        puts "PLEASE ENTER 'y' OR 'n'..."
        view_monthly_totals
      end
    elsif answer == "n"
      #showing all months
      puts " "
      $monthly_payments.each do |month, payments|
        puts "#{month}"
        puts "-" * month.length
        if payments == {}
          puts "NO PAYMENTS THIS MONTH"
          puts " "
          puts " "
        else
          #printing the amount for each payee and the monthly total, 1 time each month
            1.times do
            @monthly_total = 0.00
            payments.each do |payee, amount|
              puts "#{payee}: #{amount}"
              @monthly_total += amount
            end
            puts " "
            @monthly_total = @monthly_total.round(2)
            puts "TOTAL PAYED: #{@monthly_total}"
            puts " "
            puts " "
          end
        end
      end
    else
      puts " "
      puts "PLEASE ENTER 'y' OR 'n'..."
    end
  end

  def view_yearly_totals
    puts " "
    puts "#{$ref_year}"
    puts "-" * 4
    payee_hash = Hash.new
    year_hash = Hash.new
    #adding the amounts for each payee during the year
    $monthly_payments.each do |month, payments|
      if payments == {}
        next
      else
        payments.each do |payee, amount|
          payee_hash["#{payee}"] = amount
        end
        year_hash.merge!(payee_hash) {|key1, amount1, amount2| amount1 + amount2}
        payee_hash = {}
      end
    end
    #showing the total amount for each payee during the year, and the combined yearly total
    year_total = 0.00
    year_hash.each do |payee, amount|
      puts "#{payee}: #{amount}"
      year_total += amount
    end
    puts " "
    year_total = year_total.round(2)
    puts "YEAR TOTAL: #{year_total}"
  end

  def modify_a_payment
    def is_numeric?
      true if Float(self) rescue false
    end
    puts " "
    puts "WHAT WAS THE MONTH OF THE PAYMENT?"
    puts "> "
    required_month = $stdin.gets.chomp.upcase
    verify_empty_input(required_month)
    unless $months.include?("#{required_month}")
      puts " "
      puts "PLEASE ENTER THE NAME OF THE MONTH CORRECTLY"
    else
      if $monthly_payments["#{required_month}"] == {}
        puts " "
        puts "THERE ARE NO PAYMENTS FOR THIS MONTH"
        option
      else
        puts " "
        puts "WHAT IS THE NAME OF THE PAYEE?"
        puts "> "
        name = $stdin.gets.chomp.upcase.to_s.gsub(" ", "_")
        verify_empty_input(name)
        #verifying there are records of payments to the payee during the specified month
        unless verify_payee_in_month(name, required_month) == true
          puts " "
          puts "THERE ARE NO PAYMENTS FOR '#{name}' IN #{required_month}"
          option
        else
          puts " "
          puts "WHAT IS THE AMOUNT THAT NEEDS TO BE CORRECTED?"
          puts "> "
          input1 = $stdin.gets.chomp
          if input1.is_numeric?
            @incorrect_amount = Float(input1)
          else
            puts " "
            puts "PLEASE ENTER A NUMBER"
            option
          end
          puts " "
          puts "WHAT WAS THE CORRECT AMOUNT FOR THE PAYMENT?"
          puts "> "
          input2 = $stdin.gets.chomp
          if input2.is_numeric?
            @correct_amount = Float(input2)
          else
            puts " "
            puts "PLEASE ENTER A NUMBER"
            option
          end
          #changing the old amount for the new one
          @new_amount = 0.00
          $monthly_payments["#{required_month}"].each do |payee, amount|
            if payee == name
              amount = amount - @incorrect_amount
              @new_amount = amount + @correct_amount
            else
              next
            end
          end
          #updating the payees list if the payment corresponds to the current month
          unless required_month != $months[($time.month) -1]
            $payee_list["#{name}"] = @new_amount
          end
          #updating the record of the payment on the specified month
          $monthly_payments.each do |month, payments|
            if month == required_month
              payments["#{name}"] = @new_amount
            else
              next
            end
          end
          save_data
          puts " "
          puts "YOUR PAYMENT HAS BEEN UPDATED"
          puts " "
          puts " "
          puts "#{required_month}"
          puts "-" * required_month.length
          puts " "
          $monthly_payments.each do |month, payments|
            if month == required_month
              payments.each do |payee, amount|
                puts "#{payee}: #{amount}"
              end
            else
              next
            end
          end
        end
      end
    end
  end

  def modify_a_payee
    puts " "
    puts "ENTER THE CURRENT NAME OF THE PAYEE"
    puts "> "
    current_name = $stdin.gets.chomp.upcase.to_s.gsub(" ", "_")
    verify_empty_input(current_name)
    #verifying the payee exists
    unless $payee_list.has_key?("#{current_name}")
      puts " "
      puts "'#{current_name}' IS NOT CURRENTLY ON THE LIST"
    else
      puts " "
      puts "ENTER THE NEW NAME FOR THE PAYEE"
      puts "> "
      new_name = $stdin.gets.chomp.upcase.to_s.gsub(" ", "_")
      verify_empty_input(new_name)
      unless new_name == current_name
        $payee_list["#{new_name}"] = $payee_list.delete("#{current_name}")
        sort_payees
      else
        puts " "
        puts "THE NAMES ARE THE SAME"
      end
      #updating the payee on every month that has an entry with its name
      transition_array = []
      ordered_hash = Hash.new
      $monthly_payments.each do |month, payments|
        if payments == {}
          next
        else
          if payments.has_key?("#{current_name}")
            payments["#{new_name}"] = payments.delete("#{current_name}")
          else
            next
          end
        end
      end
      #sorting the names back into alphabetical order in the monthly payments list
      $months.each do |month_name|
        if $monthly_payments["#{month_name}"] == {}
          next
        else
          $monthly_payments["#{month_name}"].each do |payee, amount|
            transition_array << [payee, amount]
          end
          transition_array.sort!
          ordered_hash = transition_array.to_h
        end
        $monthly_payments["#{month_name}"] = ordered_hash
      end
      save_data
      puts " "
      puts "'#{current_name}' HAS BEEN RENAMED AS '#{new_name}'"
      view_expenses
    end
  end

  def delete_a_payment
    def is_numeric?
      true if Float(self) rescue false
    end
    puts " "
    puts "WHAT WAS THE MONTH OF THE PAYMENT?"
    puts "> "
    required_month = $stdin.gets.chomp.upcase
    verify_empty_input(required_month)
    unless $months.include?("#{required_month}")
      puts " "
      puts "PLEASE ENTER THE NAME OF THE MONTH CORRECTLY"
    else
      if $monthly_payments["#{required_month}"] == {}
        puts " "
        puts "THERE ARE NO PAYMENTS FOR THIS MONTH"
        option
      else
        puts " "
        puts "WHAT IS THE NAME OF THE PAYEE?"
        puts "> "
        name = $stdin.gets.chomp.upcase.to_s.gsub(" ", "_")
        verify_empty_input(name)
        unless verify_payee_in_month(name, required_month) == true
          puts " "
          puts "THERE ARE NO PAYMENTS FOR '#{name}' IN #{required_month}"
          option
        else
          puts " "
          puts "WHAT IS THE AMOUNT THAT YOU WANT TO DELETE?"
          puts "> "
          input1 = $stdin.gets.chomp
          if input1.is_numeric?
            @amount_to_delete = Float(input1)
          else
            puts " "
            puts "PLEASE ENTER A NUMBER"
            option
          end
          #substracting the amount to be deleted
          $monthly_payments["#{required_month}"].each do |payee, amount|
            if payee == name
              @reduced_amount = amount - @amount_to_delete
            else
              next
            end
          end
          #updating the payees list if deleting the amount during the current month
          unless required_month != $months[($time.month) -1]
            $payee_list["#{name}"] = @reduced_amount
          end
          #updating the new amount in the monthly payments list
          $monthly_payments.each do |month, payments|
            if month == required_month
              payments["#{name}"] = @reduced_amount
            else
              next
            end
          end
          save_data
          puts " "
          puts "YOUR PAYMENT OF '#{@amount_to_delete}' TO '#{name}' HAS BEEN REMOVED"
          view_expenses
          option
        end
      end
    end
  end

  def delete_a_payee
    puts " "
    puts "WHAT IS THE NAME OF THE PAYEE YOU WISH TO DELETE?"
    puts "> "
    name = $stdin.gets.chomp.upcase.to_s.gsub(" ", "_")
    verify_empty_input(name)
    unless $payee_list.has_key?("#{name}")
      puts " "
      puts "THAT PAYEE IS NOT CURRENTLY ON THE LIST"
      option
    else
      puts " "
      puts "WOULD YOU LIKE TO REMOVE ALL RECORDS OF PAST PAYMENTS TO THIS PAYEE (y/n)?"
      puts "> "
      answer = $stdin.gets.chomp.downcase
      if answer == "y"
        #deleting all entries for the given payee
        $payee_list.delete("#{name}")
        $monthly_payments.each do |month, payments|
          if payments != {} && payments.has_key?("#{name}")
            payments.delete("#{name}")
          else
            next
          end
        end
        save_data
        puts " "
        puts "PAYEE '#{name}' AND ALL PAST PAYMENTS HAVE BEEN REMOVED"
        puts " "
        puts "WOULD YOU LIKE TO REMOVE ANOTHER PAYEE (y/n)?"
        puts "> "
        answer2 = $stdin.gets.chomp.downcase
        if answer2 == "y"
          delete_a_payee
        elsif answer2 == "n"
          option
        else
          puts " "
          puts "PLEASE ENTER 'y' OR 'n'..."
          option
        end
      elsif answer == "n"
        #deleting the payee and updating the list only for the current month
        $payee_list.delete("#{name}")
        sort_by_month
        puts " "
        puts "PAYEE '#{name}' HAS BEEN REMOVED"
        puts " "
        puts "WOULD YOU LIKE TO REMOVE ANOTHER PAYEE (y/n)?"
        puts "> "
        answer3 = $stdin.gets.chomp.downcase
        if answer3 == "y"
          delete_a_payee
        elsif answer3 == "n"
          option
        else
          puts " "
          puts "PLEASE ENTER 'y' OR 'n'..."
          option
        end
      else
        puts " "
        puts "PLEASE ENTER 'y' OR 'n'..."
        option
      end
    end
  end

  def sort_payees
    #sorting payees names by alphabetical order
    transition_array = []
    $payee_list.each do |payee, amount|
      transition_array << [payee, amount]
    end
    transition_array.sort!
    ordered_hash = Hash.new
    ordered_hash = transition_array.to_h
    $payee_list = ordered_hash
  end

  def verify_empty_input(input)
    #verifying input is not an empty 'return'
    unless input.to_s.strip.empty? == false
      puts " "
      puts "PLEASE ENTER AN ANSWER"
      option
    end
  end

  def verify_payee_in_month(payee_name, ref_month)
    #verifying there are records of payments to the required payee in the specified month
    payee_in_month = []
    $monthly_payments.each do |month, payments|
      if month == ref_month && month != {}
        payments.each do |payee, amount|
          unless payee == payee_name
            next
          else
            payee_in_month << payee
          end
        end
      else
        next
      end
    end
    true if payee_in_month[0] == payee_name rescue false
  end

  def save_data
    write_to_file
    load_payees
    load_monthly_payments
  end

  def option
    puts " "
    puts "RETURN TO MAIN SCREEN OR QUIT (r/q)?"
    puts "> "
    answer = $stdin.gets.chomp.downcase.to_s
    if answer == "r"
      write_to_file
      start
    elsif answer == "q"
      finish
    else
      verify_empty_input(answer)
      puts " "
      puts "PLEASE ENTER 'r' OR 'q'..."
      option
    end
  end

  def finish
    write_to_file
    puts " "
    puts "THANK YOU FOR USING 'ELECTRONIC EXPENSES TRACKER'"
    puts "=" * 52
    puts "-"* 34
    puts "| Asiel Montes : v1.2 : 05-29-18 |"
    puts "-" * 34
    puts "=" * 52
    puts "/|\\    /|\\    " * 4
    sleep(3)
    exit(0)
  end

  def start
    create_file
    puts " "
    puts "\\|/    \\|/    " * 4
    puts "=" * 52
    puts " $      $     " * 4
    puts "=" * 52
    puts "WELCOME TO YOUR ELECTRONIC EXPENSES TRACKER"
    puts "WHAT WOULD YOU LIKE TO DO TODAY? (Enter a number)"
    puts " "
    puts " 1:  -ADD A NEW PAYEE \n 2:  -ADD A NEW PAYMENT  \n 3:  -VIEW CURRENT EXPENSES \n 4:  -VIEW MONTHLY TOTALS \n 5:  -VIEW YEARLY TOTALS \n 6:  -MODIFY A PAYMENT \n 7:  -MODIFY A PAYEE \n 8:  -DELETE A PAYMENT \n 9:  -DELETE A PAYEE \n 10: -QUIT \n"
    puts " "
    print "> "
    action = $stdin.gets.chomp.to_i
    case action
    when 1
      add_new_payee
      option

    when 2
      add_new_payment
      option

    when 3
      view_expenses
      option

    when 4
      view_monthly_totals
      option

    when 5
      view_yearly_totals
      option

    when 6
      modify_a_payment
      option

    when 7
      modify_a_payee
      option

    when 8
      delete_a_payment
      option

    when 9
      delete_a_payee
      option

    when 10
      finish

    else
      puts " "
      puts "PLEASE ENTER THE NUMBER OF THE OPTION"
      option
    end
  end

begin
  start

rescue
  puts " "
  puts "THE PROGRAM HAS ENCOUNTERED AN ERROR"
  puts "WOULD YOU LIKE TO RESTART IT NOW (y/n)? "
  answer = $stdin.gets.chomp.downcase
  if answer == "y"
    start
  elsif answer == "n"
    finish
  else
    puts " "
    puts "PLEASE ENTER 'y' OR 'n'..."
    option
  end
end
