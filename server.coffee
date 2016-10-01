App = require 'app'
Db = require 'db'

exports.onInstall = !->
	Db.shared.set 'inventory', 
		count: 0
		value: 0
		deposit: 0
	Db.shared.set 'transactions',
		maxId: 0

exports.onJoin = (userId) !->
	if !Db.shared.get('balances', userId)?
		Db.shared.set 'balances', userId, 0
		Db.shared.set 'users', userId,
			total: 0
			units:
				maxId: 0
			transactions:
				maxId: 0

exports.client_addTransaction = (args, cb) !->
	# Transaction data
	transaction = 
		date: App.time()
		user: App.userId()
		countChange: args.count|0
		valueChange: args.value|0
		depositChange: args.value|0
	
	# Save transaction
	id = Db.shared.incr 'transactions', 'maxId'
	Db.shared.set 'transactions', id, transaction
	uId = Db.shared.incr 'users', App.userId(), 'transactions'
	Db.shared.set 'users', App.userId(), 'transactions', uId, id

	# Update inventory
	if args.count?
		Db.shared.incr 'inventory', 'count', args.count
	if args.value?
		Db.shared.incr 'inventory', 'value', args.value
	if args.deposit?
		Db.shared.incr 'inventory', 'deposit', args.deposit

	# Update user balance
	balanceChange = ((args.value|0)+(args.deposit|0))
	Db.shared.incr 'balances', App.userId(), balanceChange

	cb.reply id

exports.client_removeTransaction = (id, cb) !->
	# TODO

exports.client_takeUnit = (cb) !->
	# Calculate average item price
	price = Math.round(Db.shared.get('inventory', 'value')/Db.shared.get('inventory', 'count'))
	log 'price', price

	# Save Transaction
	transaction = 
		date: App.time()
		user: App.userId()
		countChange: -1
		valueChange: price*(-1)
	id = Db.shared.incr 'transactions', 'maxId'
	Db.shared.set 'transactions', id, transaction

	# Update inventory
	Db.shared.incr 'inventory', 'count', -1
	Db.shared.incr 'inventory', 'value', price*(-1)

	# Update user
	Db.shared.incr 'balances', App.userId(), price*(-1)
	Db.shared.incr 'users', App.userId(), 'total'
	uId = Db.shared.incr 'users', App.userId(), 'units', 'maxId'
	Db.shared.set 'users', 'units', uId, id

	cb.reply id

exports.client_removeUnit = (id, cb) !->
	# TODO

### Database
Note: All money amounts are in cents.

inventory
	count					Number of items in inventory
	value					Total values of items in inventory
	deposit					Total value of deposits
balances
	<userId>				user as key, balance (money) as value
users			
	<userId>				Some information for every user
		total 				Total amount taken
		units 				List of 'take a unit' events for the user
			maxId
			<id>			user unit id to transaction id
		transactions		List of inventory transactions (all non 'take a unit' transactions)
			maxId
			<id>			user transaction ID to transaction id
transactions	
	maxId
	<id>
		date 				Date of the transaction
		user 				The userID of the transaction
		countChange 		The amount with which the inventory count changes (nagative for taking one)
		valueChange 		The amount with which the inventory value changes
		depositChange 		The amount with which the inventory deposit changes
###