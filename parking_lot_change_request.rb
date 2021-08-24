require 'singleton'

## Creating a class Parking Lot that have method
## create_parking_lot, create_slots, park, leave, 
## free_slots, allocated_slots , nearest_free_slot  , 
## status , tickets_having_allocated_slot , 
## tickets_details_having_allocated_slot , 
## plate_numbers_for_cars_with_colour , 
## slot_number_for_cars_with_colour , 
## slot_number_for_registration_number , 
## check_if_free_slot_available , create_parking_ticket , 
## update_slot ,  update_ticket_of_slot.
class ParkingLot
	include Singleton

	attr_accessor :total_slots, :total_parking_tickets

	def initialize(number_of_slots = 0 , hourly_rate = 0 , grace_period = 0 )
		@total_slots = send(:create_slots, number_of_slots , hourly_rate , grace_period)
		@total_parking_tickets = []
	end

	def create_parking_lot(number_of_slots , hourly_rate , grace_period)
		create_slots(number_of_slots , hourly_rate , grace_period)
	end

	def create_slots(number_of_slots = 0 , hourly_rate , grace_period)
		number_of_slots = number_of_slots.to_i
		@hourly_rate = hourly_rate.to_f
		@grace_period = grace_period
		
		@total_slots = (1..number_of_slots).to_a.inject([]) do |total_slots, slot_number|
			total_slots << Slot.new(slot_number)
			total_slots
		end
		
		print "Created a parking lot with #{number_of_slots} slots with Rupees.#{hourly_rate} of hourly rate and of #{grace_period} grace period.\n" if number_of_slots > 0
	end

	def park(car_number_plate, car_colour , entry_time)
		car = car.is_a?(Car) ? car : Car.get_new_car(car_number_plate, car_colour , entry_time)
		nearest_free_slot = check_if_free_slot_available
		@total_parking_tickets << create_parking_ticket(car, nearest_free_slot.slot_number)
		update_slot(nearest_free_slot, :allocated)
		print "Allocated slot number : #{nearest_free_slot.slot_number}\n"
	end

	def leave(registration_number , exit_time)
		ticket = tickets_having_allocated_slot.find {|ticket| ticket.registration_number == registration_number}
		raise "Invalid Registration number" if ticket.nil?
		hourly_rate = @hourly_rate
		grace_period = @grace_period.to_i
		exit_time_a = exit_time.split(":")
		entry_time = ticket.entry_time.split(":")
		total_exit_time = "#{exit_time_a[0].to_i}.#{exit_time_a[1].to_i}".to_f
		total_time_entry = "#{entry_time[0].to_i}.#{entry_time[1].to_i}".to_f
		minute_conversion_exit_time = total_exit_time * 60
		minute_conversion_entry_time = total_time_entry * 60
		car_parked_price = 0
		if entry_time[0] == exit_time_a[0]
			minute_parked = minute_conversion_exit_time - minute_conversion_entry_time
			if minute_parked > grace_period
				car_parked_price = hourly_rate
			else
				car_parked_price = 0
			end
		else
			total_hour = (minute_conversion_exit_time / 60 ).to_f - (minute_conversion_entry_time / 60).to_f
			if total_hour > 1
				car_parked_price = total_hour.ceil * hourly_rate
			else
				car_parked_price = hourly_rate
			end
		end
		slot_number = ticket.slot_number
		raise "All slots are free" if allocated_slots.empty?
		slot = allocated_slots.find{|slot| slot.slot_number.eql?(slot_number.to_i)}
		car = Car.exit_car(registration_number,exit_time)
		@total_parking_tickets[exit_time.to_f] = exit_time
		@total_parking_tickets << update_parking_ticket(car , slot_number)
		slot = update_slot(slot, :free)
		update_ticket_of_slot(slot, :out)
		print "Slot #{slot_number} is free,paid #{car_parked_price} \n"
	end

	def free_slots
		total_slots.select {|slot| slot.free?}
	end

	def allocated_slots
		total_slots.select {|slot| slot.allocated?}
	end

	def nearest_free_slot
		free_slots.min_by(&:slot_number)
	end

	def status
		ticket_details
	end

	def total_parking_tickets_details
		total_parking_tickets.select {|parking_ticket| parking_ticket}
	end

	def ticket_details
		parking_tickets = total_parking_tickets_details
		print "\n"
		print "Slot No. | Registration No. | Colour   | Entry Time |  Exit Time  |\n"
		print "---------|------------------|----------|------------|-------------|}\n"
		
		parking_tickets.each do |parking_ticket|
			if parking_ticket.status == "in"
				print "    #{parking_ticket.slot_number}    |     #{parking_ticket.registration_number}     |  #{parking_ticket.car_colour}   |   #{parking_ticket.entry_time}    |   #{parking_ticket.exit_time}   |\n"
			
			else
				print "         |     #{parking_ticket.registration_number}     |  #{parking_ticket.car_colour}   |   #{parking_ticket.entry_time}    |   #{parking_ticket.exit_time}   |\n"
			end
		end
		print "\n" 
	end


	def tickets_having_allocated_slot
		total_parking_tickets.select {|parking_ticket| parking_ticket.free? }
	end

	def tickets_details_having_allocated_slot
		parking_tickets = tickets_having_allocated_slot
		print "\n"
		print "Slot No. | Registration No. | Colour   | Entry Time |  Exit Time  |\n"
		print "---------|------------------|----------|------------|-------------|\n"
		
		parking_tickets.each do |parking_ticket|
			print "    #{parking_ticket.slot_number}   |     #{parking_ticket.registration_number}     |  #{parking_ticket.car_colour}   |   #{@exit_time}    |   #{parking_ticket.exit_time}\n"
		end
		print "\n"
	end

	def plate_numbers_for_cars_with_colour colour
		registration_number = tickets_having_allocated_slot.select {|ticket| ticket.car_colour == colour}.map {|ticket| ticket.registration_number }
		
		raise "Not Found" if registration_number.empty?
		print "#{registration_number.join(', ')}\n"
	end

	def slot_numbers_for_cars_with_colour(colour)
		slot_numbers = tickets_having_allocated_slot.select {|ticket| ticket.car_colour == colour}.map {|ticket| ticket.slot_number}
		
		raise "Not Found" if slot_numbers.empty?
		print "#{slot_numbers.join(', ')}\n"
	end

	def slot_number_for_registration_number(registration_number)
		ticket = tickets_having_allocated_slot.find {|ticket| ticket.registration_number == registration_number}

		raise "Not Found" if ticket.nil?
		print "#{ticket.slot_number}\n"
	end

	private

	def check_if_free_slot_available
		return nearest_free_slot unless free_slots.empty?
		raise "Sorry, Parking lot is full"
	end

	def create_parking_ticket(car, slot_number)
		ParkingTicket.new(car, slot_number)
	end

	def update_parking_ticket(car, slot_number)
		ParkingTicket.update(car, slot_number)
	end

	def update_slot(slot, status)
		case status
		when :allocated then slot.allocated!;
		when :free then slot.free!;
		else
			raise "Wrong slot status."
		end
	end

	def update_ticket_of_slot(slot, status)
		parking_ticket = total_parking_tickets.find do |parking_ticket|
			parking_ticket.slot_number.eql?(slot.slot_number)
		end
		case status
		when :in then parking_ticket.in!
		when :out then parking_ticket.out!
		else
			raise "Wrong ticket status."
		end
	end
end

class Slot
	SLOT_STATUSES = { free: "free" , allocated: "allocated" }

	attr_accessor :status, :slot_number

	def initialize(slot_number)
		@status 		= SLOT_STATUSES[:free]
		@slot_number 	= slot_number
	end

	def free?
		@status.eql?(SLOT_STATUSES[:free])
	end

	def allocated?
		@status.eql?(SLOT_STATUSES[:allocated])
	end

	def free!
		@status = SLOT_STATUSES[:free]
		self
	end

	def allocated!
		@status = SLOT_STATUSES[:allocated]
		self
	end
end

class ParkingTicket
	attr_accessor :registration_number, :car_colour, :slot_number, :status , :entry_time , :exit_time
 
	TICKET_STATUS = { in: "in", out: "out" }
	def initialize(car, slot_number)
		@registration_number = car.number_plate
		@car_colour = car.colour
		@entry_time = car.entry_time
		@slot_number = slot_number
		@exit_time = "NA"
		@status = TICKET_STATUS[:in]
	end

	def self.update(car, slot_number)
		@registration_number = car.number_plate
		@car_colour = car.colour
		@entry_time = car.entry_time
		@exit_time = car.exit_time
		@slot_number = slot_number
		@status = TICKET_STATUS[:out]
	end


	def in!
		@status = TICKET_STATUS[:in]
	end

	def out!
		@status = TICKET_STATUS[:out]
	end

	def free?
		@status.eql?(TICKET_STATUS[:in])
	end

	def allocated?
		@status.eql?(TICKET_STATUS[:out])
	end
end

class Car
	attr_accessor :number_plate, :colour , :entry_time , :exit_time

	def initialize(args)
		args.each do |k,v|
			instance_variable_set("@#{k}", v) unless v.nil?
		end
	end

	def self.exit_car(number_plate, exit_time)
		new({number_plate: number_plate, exit_time:exit_time })
	end

	def self.get_new_car(number_plate, colour , entry_time)
		new({number_plate: number_plate, colour: colour , entry_time: entry_time})
	end
end

def execute_line(line)
	line_data = line.split(' ')
	method_name = line_data.shift
	args = line_data
	begin
		if args.empty?
			exit(true) if method_name.eql?("exit")
			ParkingLot.instance.send(method_name)
		else
			ParkingLot.instance.send(method_name, *args)
		end
	rescue StandardError => exception
		print "#{exception.message}\n"
	end
end

if ARGV.length > 0
	filename = ARGV.first.chomp
	File.foreach("#{filename}") do |line|
		execute_line(line)
	end
else
	while (command = STDIN.gets.chomp()) != 'exit'
		execute_line(command)
	end
end

