App = require 'app'
Db = require 'db'
Dom = require 'dom'
Form = require 'form'
Modal = require 'modal'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'

{tr} = require 'i18n'

# Some balance code is copied from the Happening plug-in Split the Bill (https://github.com/Happening/SplitTheBill/)

exports.render = !->
	if Page.state.get(0) == 'balances'
		renderBalances()
	else if Page.state.get(0) == 'inventory'
		if Page.state.get(1) == 'add'
			renderInventoryAdd()
		else
			renderInventory()
	else
		renderOverview()

renderOverview = !->
	# Title bar icons
	Page.setActions
		icon: 'add'
		label: tr('Add items')
		action: !->
			Page.nav ['inventory', 'add']

	# Balances
	Dom.section !->
		Dom.div !->
			balance = Db.shared.get('balances', App.userId())||0
			Dom.style Box: 'horizontal'
			Dom.div !->
				Dom.text tr("Show all balances")
				Dom.style
					Flex: true
					color: App.colors().highlight
					marginTop: '1px'
			Dom.div !->
				Dom.text tr("You:")
				Dom.style
					textAlign: 'right'
					margin: '1px 10px 0 0'
			Dom.div !->
				Dom.style
					fontWeight: "bold"
					fontSize: '120%'
					textAlign: 'right'
				stylePositiveNegative(balance)
				Dom.text formatMoney(balance)
		Dom.onTap !->
			Page.nav ['balances']
		Dom.style padding: '16px'

	# Inventory
	Dom.section !->
		Dom.div !->
			Dom.style Box: 'horizontal'
			Dom.div !->
				Dom.text tr("Inventory")
				Dom.style
					Flex: true
					color: App.colors().highlight
					marginTop: '1px'
			Dom.div !->
				Dom.style
					fontWeight: "bold"
					fontSize: '120%'
					textAlign: 'right'
				Dom.text Db.shared.get('inventory', 'count') 
		Dom.onTap !->
			Page.nav ['inventory']
		Dom.style padding: '16px'
	
	# Take a beer button
	Ui.bigButton tr("I Took a Beer"), !->
		Server.call 'takeUnit', (data) !->
			if data == false
				Modal.show tr("There are no beers left...")
			else
				Modal.show tr("Success")

	# Log of my recent beers



renderBalances = !->
	Dom.text "Balances"


renderInventory = !->
	Dom.text "Inventory"


renderInventoryAdd = !->
	Page.setTitle tr("Add items")
	
	Form.setPageSubmit (result) !->
		log(result)
		items = parseInt(result.items)
		price = parseFloat(result.price)*100
		deposit = parseFloat(result.deposit)*100
		if items == NaN or price == NaN or deposit == NaN
			log(typeof items)
			log(typeof price)
			log(typeof deposit)
			Modal.show tr("Not a fields are submitted correctly")
			return

		# Data correct
		params = 
			count: items
			value: price
			deposit: deposit
		Server.call 'addTransaction', params, (result) !->
			Page.nav ['']
	, 0

	Dom.h2 tr("Amount of items")
	Form.input
		name: 'items'
		text: tr("Items")
		value: 24
	Dom.h2 tr("Price (without deposit)")
	Form.input
		name: 'price'
		text: tr("Price")
	Dom.h2 tr("Price deposit")
	Form.input
		name: 'deposit'
		text: tr("Deposit")
		value: 3.90



# Support methods, borrowed from the Split the Bill app
formatMoney = (amount) ->
	amount = Math.round(amount)
	currency = "€"
	if Db.shared.get("currency")
		currency = Db.shared.get("currency")
	string = amount/100
	if amount%100 is 0
		string +=".00"
	else if amount%10 is 0
		string += "0"
	return currency+(string)

stylePositiveNegative = (amount) !->
	if amount > 0
		Dom.style color: "#080"
	else if amount < 0
		Dom.style color: "#E41B1B"