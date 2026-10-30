extends Node
## Hollowmere lore, villagers, recipes and the daily request generator.
## Autoload name: Story

const TITLE := "Hollowmere"

const INTRO := [
	["Letter from the Academy", "Apprentice,\n\nYou are assigned to Hollowmere, the village below Ashenvale Academy. Since the Quiet Night the lanterns there have been dimming, and the old apothecary stands empty."],
	["Letter from the Academy", "Reopen it. Grow what the garden still offers, brew what the villagers need, and keep the Ember of the village alive.\n\nWhen the Ember burns bright enough, the Academy gate will open for you.\n\n— Headmistress Oriel Vance"],
	["", "Walk with WASD or the joystick. Press ACT (F) near plants, the cauldron, villagers and the notice board. Moonpetal only blooms after dark."],
	["", "Press M for the valley map. The Academy gate on the hill opens when the village Ember reaches 12 — fill requests, brew, and light what you can. Up there you will be sorted into an Order and the lessons begin."],
]

const RECIPES := {
	"potion": {"name": "Starlight Potion", "needs": {"moonpetal": 1, "emberroot": 1, "whisperleaf": 1}, "blurb": "Brightens any lantern. The Academy's favourite."},
	"tonic": {"name": "Warmth Tonic", "needs": {"emberroot": 2}, "blurb": "Keeps a cold cottage cosy through the night."},
	"draught": {"name": "Dream Draught", "needs": {"moonpetal": 2, "whisperleaf": 1}, "blurb": "Quiet sleep and clear dreams."},
	"elixir": {"name": "Ember Elixir", "needs": {"emberroot": 2, "moonpetal": 1, "whisperleaf": 1}, "blurb": "Bottled village warmth. Worth 3 Ember when brewed.", "locked": true},
	"shade": {"name": "Shade Draught", "needs": {"nightcap": 2, "moonpetal": 1}, "blurb": "Brewed from the Hollow Wood's Nightcap. Wennet's recipe. Sells for 25.", "locked": true},
	"glow": {"name": "Glowbrew", "needs": {"sunbell": 2, "emberroot": 1}, "blurb": "Isolde's recipe. Lights every lantern in sight when drunk; sells for 30.", "locked": true},
	"pie": {"name": "Fernmoor Fish Pie", "needs": {"perch": 1, "whisperleaf": 1, "emberroot": 1}, "blurb": "Dilly's recipe. A gift that every villager loves (friendship +2), and the Academy students adore it.", "locked": true},
	"oil": {"name": "Lantern Oil", "needs": {"whisperleaf": 1, "minnow": 1}, "blurb": "Corvin's recipe. Burns clean and sells well at the market.", "locked": true},
	"broth": {"name": "Heron Broth", "needs": {"perch": 1, "emberroot": 1}, "blurb": "Corvin's recipe. Every villager loves a bowl (gift: friendship +2).", "locked": true},
}

## Library tomes (Chapter 3). Reading all of them earns the Ember Elixir recipe.
const BOOKS := {
	"founding": {"title": "On the Founding of Ashenvale", "pages": [
		"In the year the river froze twice, the mage Ashen Vale built a tower on the hill above a nameless hollow, and lit a lantern in its window so travellers could find her.",
		"Travellers came. Some stayed. The hollow became Hollowmere, and the tower became a school, and the lantern was never allowed to go out.\n\nThat lantern is the shrine candle in the square."]},
	"quiet": {"title": "The Quiet Night: A Record", "pages": [
		"Nine years ago, on the longest night, every flame in Ashenvale guttered at once. No storm, no spell that anyone would admit to. By dawn, half the Academy had left.",
		"Headmistress Vance stayed. Professors Alder and Isolde stayed. The village stayed, because villages do.\n\nThe shrine candle was the only light that did not go out."]},
	"herbal": {"title": "Thornquist's Herbal, abridged", "pages": [
		"Moonpetal opens only in darkness and closes at the first grey of dawn. Emberroot is warm to the touch; a bed of it will melt a frost. Whisperleaf rustles when someone nearby tells a lie.",
		"Mirabel Thornquist's note in the margin: 'All three together, with a steady hand and an honest heart, make something the old books called Ember Elixir. I never managed it. Perhaps you will.'"]},
	"kindle": {"title": "First Flame: Notes for Apprentices", "pages": [
		"Kindle is not about fire. It is about attention. The spell finds what wants to burn and gives it permission.",
		"Alder's handwriting: 'Students who cannot Kindle a cold lantern are usually not paying attention to the lantern. They are paying attention to themselves.'"]},
	"stars": {"title": "An Almanac of the Ashenvale Sky", "pages": [
		"Three constellations are seen only from this valley: the Lantern-Bearer in the north, the Crooked Bridge low in the east, and Ashen's Wheel overhead.",
		"Seraphine Lowe's note: 'On the Quiet Night the Wheel burned white. I have never written that down before. I am writing it now because someone has finally come to read it.'"]},
	"r_watch": {"title": "[Restricted] The Watch-Fires of the Valley", "restricted": true, "pages": [
		"Before the Academy there were three fires: the Watchtower, the isle lantern, and the hearth that became the shrine. They were lit from one another in a ring, every midwinter, by someone who walked the whole valley in a night.",
		"The ring was last walked nine years ago by the Watchman. He did not finish. The Headmistress has the letter that says why."]},
	"r_wheel": {"title": "[Restricted] On the Turning of the Wheel", "restricted": true, "pages": [
		"Ashen's Wheel does not turn because the sky moves. It turns because the valley does: eight stars, eight lanterns of consequence, and when one goes dark the Wheel sticks.",
		"Margin, in Marrow's hand: 'If this is true then the Quiet Night was not an attack. It was a stuck wheel. Somebody should have oiled it. Somebody should go up.'"]},
	"r_small": {"title": "[Restricted] A Note on the Small Star", "restricted": true, "pages": [
		"A star that approaches is a star that was sent. Every valley with a Wheel has, once in its history, sent a light outward to find help, and once in its history had that light come home.",
		"Seraphine Lowe, last page, recent ink: 'It is coming home. I have told the apprentice. I have not told the apprentice what we sent it for. We sent it for them.'"]},
	"ember": {"title": "What the Ember Is", "pages": [
		"Every village keeps an Ember. It is not a thing but a sum: each lantern lit, each neighbour helped, each potion brewed for someone else.",
		"When the Ember is low, gates close and magic grows shy. When it is high, the old doors remember how to open. Ashenvale's gate is one such door. There are others."]},
}

## Lost pages of Quill's catalogue, hidden around the village (Chapter 3).
const LOST_PAGES := {
	"page_well": {"pos": Vector3(10.5, 0, 14.0), "hint": "one fell by the well"},
	"page_tower": {"pos": Vector3(-17.5, 0, -14.0), "hint": "one blew up to the witch's tower"},
	"page_mill": {"pos": Vector3(24.0, 0, -8.5), "hint": "one is somewhere near the windmill"},
}

## Decorations sold at the market. pos: where they appear in the village.
const DECOR := {
	"pumpkins": {"name": "Pumpkin patch", "price": 10, "model": "halloween/pumpkin_orange_jackolantern.gltf", "pos": Vector3(-3.5, 0.12, 8.0), "scale": 0.8},
	"bench": {"name": "Garden bench", "price": 12, "model": "halloween/bench.gltf", "pos": Vector3(-9.0, 0, -9.5), "scale": 1.0},
	"lantern": {"name": "Hanging lantern post", "price": 18, "model": "halloween/post_lantern.gltf", "pos": Vector3(12.0, 0, 7.5), "scale": 1.0},
	"flag": {"name": "Academy banner", "price": 25, "model": "hex/decoration/props/flag_blue.gltf", "pos": Vector3(-6.0, 0, -14.0), "scale": 5.0},
}

## Furniture for your cottage, sold at the Lantern Market stall.
const HOME_DECOR := {
	"bookshelf": {"name": "Tall bookshelf", "price": 20, "model": "dungeon/shelves.gltf.glb", "pos": Vector3(-5.6, 0, -1.0), "rot": 90.0, "scale": 0.85},
	"banner": {"name": "Blue wall hanging", "price": 15, "model": "dungeon/banner_patternB_blue.gltf.glb", "pos": Vector3(-3.0, 1.4, -9.3), "rot": 0.0, "scale": 0.9},
	"kegs": {"name": "Cider kegs", "price": 14, "model": "dungeon/keg_decorated.gltf.glb", "pos": Vector3(5.6, 0, 0.5), "rot": 20.0, "scale": 0.85},
	"candles": {"name": "Candle shelf", "price": 12, "model": "dungeon/shelf_small_candles.gltf.glb", "pos": Vector3(5.9, 1.0, -5.0), "rot": -90.0, "scale": 0.85},
	"pumpkin": {"name": "Pet pumpkin", "price": 8, "model": "halloween/pumpkin_orange_jackolantern.gltf", "pos": Vector3(2.5, 0, -1.0), "rot": 30.0, "scale": 0.7},
	"crates": {"name": "Supply crates", "price": 10, "model": "dungeon/box_stacked.gltf.glb", "pos": Vector3(-5.4, 0, 1.2), "rot": 0.0, "scale": 0.8},
}

## Morning letters: one per real day, from a random villager, with a small gift.
const LETTERS := [
	["wren", "Left this at the board for you. Hill was icy. Legs still noodles. Here's a few coins for the trouble of reading my handwriting.", "coins", 4],
	["mirabel", "Spare Whisperleaf from the back bed. Don't waste it on tea.", "whisperleaf", 2],
	["bramble", "Found an Emberroot growing in my woodpile. Figured it's yours by rights.", "emberroot", 2],
	["pellam", "A coin from the Academy's old purse. For a Starlight Potion, one day, when you have one spare.", "coins", 6],
	["pip", "i drew you a picture but wren said it wouldnt fit in the letter so here is a moonpetal instead", "moonpetal", 1],
	["hatch", "Wren carried this across the bridge for me. Coins from the Fernmoor jar; the lake was kind this week.", "coins", 5],
	["alder", "Homework reminder, in case the board blows away: come to Flamecraft. Enclosed, an Emberroot I did not set fire to.", "emberroot", 1],
	["isolde", "The greenhouse Moonpetal opened at the same minute as Mirabel's last night. I thought you should know. One for you.", "moonpetal", 1],
	["quill", "A coin found between pages 40 and 41 of the founding record. It is older than the coin. Keep it.", "coins", 7],
	["corvin", "Whisperleaf. Fresh. Do not tell it anything you would not say to Mirabel.", "whisperleaf", 2],
	["seraphine", "The small star moved again. Two coins for the telescope fund, which is me.", "coins", 4],
	["nell", "The sheep sent this. I am only the courier. (It is a coin. The sheep do not have coins. I do not know where it came from.)", "coins", 3],
]

## Villagers. model: KayKit character file. home: where they stand by day.
const NPCS := {
	"wren": {
		"name": "Wren", "role": "Courier", "model": "Rogue", "pos": Vector3(5.5, 0, 6.5), "face": 200.0, "scene": "village",
		"schedule": [[9.0, 12.0, Vector3(30.0, 0, -11.0), 200.0], [12.0, 13.0, Vector3(-54.0, 0, 40.0), 60.0], [13.0, 14.0, Vector3(34.0, 0, -31.0), 200.0], [14.0, 15.0, Vector3(-33.0, 0, -7.0), 90.0], [15.0, 17.0, Vector3(5.5, 0, 6.5), 200.0], [17.0, 19.0, Vector3(-1.0, 0, 27.0), 90.0], [19.0, 21.5, Vector3(-3.0, 0, -4.0), 90.0, "tavern"]],
		"color": Color(0.6, 0.9, 1.0),
		"intro": ["Oh! A new apprentice. Finally.", "I'm Wren, I carry the post up and down the hill. The notice board by the shrine has what people need today.", "Bring folks what they ask for and the whole village warms up. You'll see the lanterns change."],
		"chat": ["The Academy used to send letters every week. Now the gate just sits there.", "Moonpetal only opens after dark. Don't let anyone tell you otherwise.", "I ran the hill three times today. My legs are made of noodles.", "If the board is empty, come back tomorrow. New day, new asks.", "I do a round now: Fernmoor at noon, Ashford at one, the market, then the square. If you need me, follow the road.", "There's a boat at the dock that goes to the isle. Marrow's out there. He waves. I wave. It's a whole thing.", "Gorrin's selling brooms now. BROOMS. I carried letters up that hill on foot for nine years."],
		"friend": ["You're alright, apprentice.", "Honestly, you're the best thing to happen to this village in years.", "If the gate ever opens, I'm carrying your trunk up there myself."],
	},
	"mirabel": {
		"name": "Mirabel Thornquist", "role": "Old herbalist", "model": "Rogue_Hooded", "pos": Vector3(-11.5, 0, -3.0), "face": 120.0, "scene": "village",
		"schedule": [[17.0, 19.0, Vector3(3.0, 0, 31.0), 250.0], [19.0, 21.5, Vector3(-4.0, 0, -1.5), 120.0, "tavern"]],
		"color": Color(0.8, 1.0, 0.7),
		"intro": ["So they sent a child to reopen my old shop. Hm.", "I kept three beds alive through the Quiet: Moonpetal, Emberroot, Whisperleaf. Harvest them, they grow back on their own.", "The cauldron remembers more recipes than I do. Try things."],
		"chat": ["Emberroot likes to be picked in the afternoon, but it won't sulk if you're late.", "A Warmth Tonic is just two Emberroot and patience.", "The shrine candles never go out. Nobody knows why. I stopped asking.", "Dream Draught: two Moonpetal, one Whisperleaf. Don't drink it before noon.", "Nightcap grows in the Hollow Wood. Purple, after dark. Don't eat it raw; I did, once, and talked to a chair for an hour.", "If you expand the garden, plant Moonpetal nearest the cottage. It likes the window light.", "Corvin keeps a bottle of mine on his top shelf. Tell him to drink it. It was always meant to be drunk."],
		"friend": ["You've got good hands for this.", "I'd have made you my apprentice myself, Academy or not.", "When I'm gone, the garden is yours. Don't argue."],
	},
	"bramble": {
		"name": "Bramble", "role": "Woodcutter", "model": "Barbarian", "pos": Vector3(-13.0, 0, 11.0), "face": 20.0, "scene": "village",
		"schedule": [[9.0, 12.0, Vector3(33.0, 0, -14.0), 150.0], [19.0, 21.5, Vector3(-5.5, 0, -7.0), 60.0, "tavern"]],
		"color": Color(1.0, 0.75, 0.55),
		"intro": ["BIG axe, small village. That's me.", "Tavern's mine too. Cold nights up here, so folks come for the fire.", "If you ever brew something warm, I'll trade you stories for it."],
		"chat": ["Cut forty logs this morning. The forest grows back faster than I cut. Suspicious.", "Pumpkins by my door are decoration. Mostly.", "Heard a bell from the Academy last night. First time in years.", "A Warmth Tonic and a good fire, that's a winter sorted.", "Pip plays with the tavern cat all morning. The cat has opinions about it.", "Mend spell fixed my fence before I'd even noticed it was broken. Witchcraft. Good witchcraft.", "Sheep at Ashford make a noise like a door. Nell says that's normal. Nell is from Ashford."],
		"friend": ["You're one of us now, apprentice.", "Next log I cut has your name on it. For a bed. Proper one.", "Whatever's behind that gate, you knock, I'll be right behind you."],
	},
	"pellam": {
		"name": "Sir Pellam", "role": "Gatekeeper", "model": "Knight", "pos": Vector3(3.5, 0, -11.0), "face": 180.0, "scene": "village",
		"schedule": [[14.0, 16.0, Vector3(-30.0, 0, -29.0), 0.0], [19.0, 21.5, Vector3(3.5, 0, -6.5), 240.0, "tavern"], [21.5, 24.0, Vector3(3.5, 0, -11.0), 180.0]],
		"night_owl": true,
		"color": Color(0.85, 0.85, 1.0),
		"intro": ["Halt. ... I jest. Nobody has come this way in a long while.", "I guard the road to Ashenvale. Guarded. The gate will not open for me.", "They say it answers to the village Ember. Warm the village, apprentice, and we shall see."],
		"chat": ["The arch was raised the year the Academy was founded. Every stone has a name.", "Starlight Potion was the Academy's drink of choice. I have not tasted one in nine years.", "At night the gate glows a little. I pretend not to notice.", "Stand straight. The Headmistress sees everything. Probably.", "Duelling drill, two till four, Trial Field. Bring every spell you have. I call, you cast.", "The Academy gate opens for Ember. Not for coin, not for rank. Ember. The village decides.", "A knight should know the map. Press M. I had it drawn by the Moonquill girl, Ivy. She charged me."],
		"friend": ["You have the bearing of a real mage now.", "I shall write to the Headmistress about you. Favourably.", "When the gate opens, walk through first. You earned it."],
	},
	"oriel": {
		"name": "Headmistress Oriel Vance", "role": "Headmistress", "model": "Rogue_Hooded", "tint": Color(0.75, 0.6, 1.0), "pos": Vector3(0, 0, -12.0), "face": 180.0, "scene": "academy",
		"schedule": [[11.0, 17.0, Vector3(25.2, 0, -18.8), 180.0]],
		"color": Color(0.85, 0.7, 1.0),
		"intro": ["So. The village Ember burns again, and the gate remembered how to open. Well done, apprentice.", "Ashenvale is not what it was. Two professors stayed through the Quiet; the rest went where the light went.", "Learn what they can teach you. Then do something I cannot: go back down and light the lanterns that went dark. Four of them. Bring the village back to me, lantern by lantern."],
		"chat": ["Professor Alder teaches Kindle in the east hall. He will be gruff. He is always gruff.", "Professor Isolde keeps the greenhouse room. Verdant is her life's work.", "The library is not ready to be opened. Soon.", "When the dark lanterns are lit, come and see me."],
		"friend": ["You remind me of myself. That is not entirely a compliment.", "The Academy will reopen. I did not believe that a month ago.", "There is a room upstairs with your name on the door. One day."],
	},
	"alder": {
		"name": "Professor Alder", "role": "Master of Flame", "model": "Knight", "tint": Color(1.0, 0.7, 0.5), "pos": Vector3(11.0, 0, -4.0), "face": 250.0, "scene": "academy",
		"schedule": [[17.0, 19.0, Vector3(-3.0, 0, -11.0), 150.0]],
		"color": Color(1.0, 0.75, 0.5),
		"teaches": "kindle",
		"intro": ["You are late. By nine years. Sit. Stand. Whatever.", "Kindle. The first spell. Warmth from will. Point, breathe, mean it.", "There. It is in you now. Press 1 near anything that should be burning and is not. The brazier here. The dead lanterns in the village."],
		"chat": ["A lantern lit by Kindle never quite goes out. Remember that.", "Flame is not anger. Flame is attention.", "Four dark lanterns in Hollowmere. I counted from the tower.", "Trial Field braziers go cold each morning. Light all three before Herbology and I will pretend not to be impressed.", "Tobin Kindles like he is angry at the fuel. You Kindle like you are asking. Keep asking.", "The common room hearth never goes out. I check. Every night. Do not tell the students."],
		"friend": ["Hm. You are not hopeless.", "If I had a student like you before the Quiet, I would not have let them leave.", "Go on. The room is yours when I am not in it."],
	},
	"isolde": {
		"name": "Professor Isolde", "role": "Keeper of the Greenhouse", "model": "Rogue", "tint": Color(0.6, 1.0, 0.7), "pos": Vector3(-11.0, 0, -4.0), "face": 110.0, "scene": "academy",
		"schedule": [[17.0, 19.0, Vector3(3.0, 0, -11.0), 210.0]],
		"color": Color(0.6, 1.0, 0.7),
		"teaches": "verdant",
		"intro": ["Mind the seedlings. Good. You stepped around them. You will do.", "Verdant does not force a plant. It asks nicely, and plants usually say yes.", "Press 2 near a herb bed and watch. Once a day per bed; more than that is rude."],
		"chat": ["Mirabel and I trained together. Tell her the roses survived.", "Moonpetal was bred here, in this room, two hundred years ago.", "Emberroot grows faster if you talk to it. I have no proof. I do it anyway.", "Fen is growing something in the back corner. I know exactly what it is. Let the child have a secret.", "The three beds in the Trial Field are the Academy's, but the herbs are the village's. Take them.", "Nightcap will not grow in my greenhouse. It wants graves nearby. Herbs are strange."],
		"friend": ["You have a gardener's patience.", "When the greenhouse is full again, half of it is yours.", "I wrote to the Headmistress about you. Twice."],
	},

	"quill": {
		"name": "Archivist Quill", "role": "Librarian", "model": "Rogue_Hooded", "tint": Color(0.55, 0.7, 1.0), "pos": Vector3(0, 0, -21.5), "face": 180.0, "scene": "academy",
		"schedule": [[17.0, 19.0, Vector3(-5.0, 0, -10.0), 140.0]],
		"color": Color(0.65, 0.8, 1.0),
		"intro": ["Shh. Not because of the books. Because of the dust; it startles.", "I am Quill. I keep what is left of the library. Most of it left with the light; what stayed is on these shelves.", "Three pages of my catalogue blew out of the window during the Quiet and never came back. One fell by the well, one blew up to the witch's tower, one is somewhere near the windmill. Bring them, and read the books. Reading counts."],
		"chat": ["Every book here has been read at least once since the Quiet. By me. It does not count.", "The founding record is the oldest thing in the building. Older than the building, technically.", "If a page glows, it is mine. Pages do not glow on their own.", "The Founders' Cards are in chests, twelve of them. Bring me the full set and I will say something kind.", "Ivy has asked me forty-one questions this term. I have answered thirty-nine. The other two are mine.", "Lark shelves books better than I do. Do not tell her. Tell her. No. Do not."],
		"friend": ["You read like someone who means it.", "I have put your name in the catalogue. Under 'friends of the library'. It is a short list.", "There is a second floor. There has always been a second floor. Ask me again when the Ember is brighter."],
	},
	"pip": {
		"name": "Pip", "role": "Bramble's kid", "model": "Rogue", "tint": Color(1.0, 0.9, 0.6), "scale": 0.42, "pos": Vector3(8.5, 0, 10.0), "face": 220.0, "scene": "village",
		"schedule": [[9.0, 14.0, Vector3(-12.5, 0, 9.0), 160.0], [14.0, 19.0, Vector3(6.0, 0, 25.0), 180.0], [19.0, 21.5, Vector3(-30.0, 0, -13.0), 90.0]],
		"color": Color(1.0, 0.9, 0.5),
		"intro": ["Are you the wizard? You have the hat so you're the wizard.", "Dad says the Academy is closed but I saw a light up there. I SAW it.", "If you learn a spell can you show me? Just one. A small one."],
		"chat": ["I'm not allowed near the cauldron. I was near it ONCE.", "Wren lets me carry the small letters. The big ones have words in them.", "At night the fountain-thing glows. I'm not scared of it. I'm not.", "Do a spell. Do a spell. Do a spell.", "The cat lets ME pick it up. Only me. And Wren. And Mirabel. And you, probably.", "I saw the fireworks from the roof. Dad said get down. I got down AFTER.", "Can you fly? Can you fly over my house? Can you fly over my house and wave?"],
		"friend": ["You're my favourite wizard. You're the only wizard but still.", "When I'm big I'm going to the Academy and you're going to be my teacher.", "I told everyone at the tavern you're the best. Dad said I'm right."],
	},

	"hatch": {
		"name": "Hatch", "role": "Ferryman of Fernmoor", "model": "Knight", "tint": Color(0.7, 0.55, 0.4), "pos": Vector3(-55.5, 0, 39.5), "face": 60.0, "scene": "village",
		"color": Color(0.8, 0.9, 1.0),
		"intro": ["Hollowmere sent someone? Across the Wend? Well. Sit by the well, you've walked far.", "Fernmoor is smaller, quieter, and we like it that way. The river feeds us; the lake up north feeds the river.", "If you ever need to cross to the far shore, I have a boat. It leaks. It has always leaked."],
		"chat": ["The Old Watchtower had a light last winter. Nobody from Fernmoor went to look. Nobody from Fernmoor ever does.", "Lake Mirren is deep in the middle. Deeper than it should be, if you ask the fish.", "My father built the bridge on the Hollowmere road. Every third stone is crooked. On purpose, he said.", "Bring Bramble's tonic sometime. He owes me a drink from nine years back.", "The Hollow Wood's got a grey lady in it. She's polite. Say hello first; she's shy about going second.", "Heron Isle's where I keep the second boat. The first boat is the leaky one. They're the same boat.", "Fish bite best at dusk, off the dock, when the lantern's just lit. Don't tell Tamsin or she'll raise her prices."],
		"friend": ["You're welcome on this side of the river any time.", "The boat is yours when you want it. Bring a bucket.", "If Fernmoor ever gets its own Ember, I know who lit it."],
	},
	"tamsin": {
		"name": "Tamsin", "role": "Grocer, Lantern Market", "model": "Rogue", "tint": Color(1.0, 0.8, 0.75), "pos": Vector3(27.0, 0, -8.5), "face": 240.0, "scene": "village", "shop": true,
		"color": Color(1.0, 0.8, 0.7),
		"intro": ["Herbs in, potions out, coins either way. That's the stall.", "I buy what you brew and sell what Mirabel's beds are short on. Fair prices. Mostly.", "Market opens at eight and I pack up at six. Don't knock after."],
		"chat": ["Starlight Potion sells best. Everyone wants their lantern brighter.", "Bramble pays in firewood. I have a lot of firewood.", "Fernmoor folk come on market days. Hatch haggles like a fish.", "If the Academy ever orders again, I'm retiring.", "Market Day's Saturday. I pay half again on everything. Bring the Moonfish.", "The cottage furniture's from Gorrin's cousin in Ashford. Don't ask about the pumpkin.", "Lantern Oil from Corvin's recipe burns clean. I'd buy a crate. I'd buy two."],
		"friend": ["I'll keep the good Emberroot under the counter for you.", "You're the only customer who pays on time.", "Half this stall is yours if you want it. Don't want it. Just saying."],
		"schedule": [[18.0, 21.5, Vector3(0.0, 0, -8.5), 180.0, "tavern"]],
	},
	"gorrin": {
		"name": "Gorrin", "role": "Smith, Lantern Market", "model": "Barbarian", "tint": Color(0.75, 0.7, 0.8), "pos": Vector3(36.0, 0, -4.0), "face": 270.0, "scene": "village",
		"color": Color(0.85, 0.8, 0.95),
		"intro": ["Lantern frames. Cauldron rivets. Gate hinges. If it's iron in Hollowmere, I hit it.", "The dark lanterns? I made every one of those. Nothing wrong with the iron. It's the light that left.", "Pellam says the gate hinge is stiff. Tell him to oil it himself."],
		"chat": ["The market stall sells my brackets as 'decor'. Decor. Hah.", "Trial Field targets are mine too. Scorch them all you like.", "Sir Pellam's armour squeaks. I offered. He declined.", "Quiet Night, the forge went cold for the first time in sixty years. Took me a week to get it back.", "The ring course on the green is mine too. Pip helped. Pip 'helped'.", "Staff crystals: Riverglass is free because it's a river. Rocks are everywhere. The others cost.", "The Watchtower brazier was the last thing I ever forged for the old Watchman. Light it, if you get the chance."],
		"friend": ["Good hands. Steady. You'd make a smith if the magic ever runs out.", "I put a new hinge on the apothecary door. No charge.", "If the Ember ever needs iron, you know where I am."],
		"schedule": [[18.0, 21.5, Vector3(4.5, 0, -2.5), 270.0, "tavern"]],
	},

	"corvin": {
		"name": "Master Corvin", "role": "Potions Master", "model": "Rogue_Hooded", "tint": Color(0.45, 0.4, 0.55), "pos": Vector3(-12.6, 0, -18.5), "face": 160.0, "scene": "academy",
		"schedule": [[17.0, 19.0, Vector3(5.0, 0, -10.0), 220.0]],
		"color": Color(0.75, 0.65, 0.95),
		"teaches": "mend",
		"intro": ["Door. Close it. Fumes.", "I am Corvin. Potions. Mirabel learned here, under me, before she decided the village needed her more than I did. She was right, which is worse.", "Evenings, seven to nine. Bring herbs. Bring patience. The cauldron here is older than the school and it knows when you are guessing."],
		"chat": ["A Dream Draught brewed angry is a nightmare in a bottle. Breathe first.", "Nine years without a student. The bottles kept their labels. I did not keep my temper.", "The Ember Elixir is not in any book. It is in the margin of one. Mirabel's margin.", "Isolde grows them, I boil them, Alder sets them on fire. It is a system.", "Full marks in my lesson and I write you two recipes. Lantern Oil. Heron Broth. Both sell. One is kind.", "The dungeon cat is not mine. It arrived. Cats do.", "Mirabel's bottle is on the top shelf. Yes, still. Yes, I know."],
		"friend": ["You stir like someone who listens.", "The dungeon key is on the hook. I never gave Mirabel one.", "When you brew the Elixir, bring me a drop. For the record. Not for me."],
	},
	"seraphine": {
		"name": "Professor Seraphine Lowe", "role": "Astronomer", "model": "Rogue", "tint": Color(0.55, 0.6, 1.0), "pos": Vector3(2.5, 0, -30.0), "face": 200.0, "scene": "academy",
		"schedule": [[17.0, 19.0, Vector3(0.0, 0, -9.5), 180.0]],
		"color": Color(0.7, 0.75, 1.0),
		"teaches": "glimmer",
		"intro": ["Look up. No, properly. The ceiling is not there; I had it taken off.", "Seraphine. Astronomy. The sky over Ashenvale has three constellations nobody else can see, and I will teach you all of them after nine at night.", "The Lantern-Bearer, the Crooked Bridge, Ashen's Wheel. Learn them and you will never be lost in Hollowmere after dark."],
		"chat": ["The Quiet Night, the stars were brighter than I have ever seen them. As if something had been taken from below and given to above.", "Hatch's bridge is in the sky too, you know. Every third star is crooked.", "Pip asked me if the moon is a lantern. I said yes. I am not sorry.", "The telescope is older than Corvin's cauldron and twice as stubborn.", "Midnight, after the isle is lit, look again. I will not say what for. Look.", "Ivy did the maths on the small star with me. She was right three times. I was right twice. We are not keeping score.", "The tower has no roof because a roof is a decision not to look up."],
		"friend": ["You have the patience for the sky.", "I named a star after you. It is very small. It is also real.", "Some night, when the Ember is bright, we will see what the Watchtower was watching."],
	},

	"nell": {
		"name": "Nell", "role": "Shepherd of Ashford", "model": "Rogue", "tint": Color(0.95, 0.92, 0.85), "pos": Vector3(34.0, 0, -33.0), "face": 240.0, "scene": "village",
		"color": Color(1.0, 0.95, 0.85),
		"intro": ["Mind the sheep. They mind you back.", "Ashford's three houses and a windmill, and the flock. We send wool down to Tamsin and get gossip back.", "The Watchtower road goes past my gate. Nobody takes it. You will, I expect."],
		"chat": ["Six sheep. I count them twice a day and get seven once a week.", "The windmill turned backwards on the Quiet Night. Just once. Then it was fine.", "Pip tried to ride a sheep last spring. The sheep won.", "Wool for the Academy banners came from this hill. Still does, if they ever ask.", "Wren comes by at one. The sheep line up for her. She's never once brought them anything.", "The Hollow Wood is past the Trial Field, north-west. Don't go at night. Do go at night. I can't decide.", "Six sheep, three houses, one windmill, one shepherd. Ashford's whole census. You're welcome."],
		"friend": ["The sheep like you. That is rarer than you think.", "If you ever want a quiet morning, the hill is yours.", "I named the small one after you. It is the stubborn one."],
	},
	"marrow": {
		"name": "Old Marrow", "role": "Hermit of Heron Isle", "model": "Rogue_Hooded", "tint": Color(0.5, 0.55, 0.5), "pos": Vector3(66.0, 0, 12.0), "face": 250.0, "scene": "village",
		"color": Color(0.8, 0.9, 0.8),
		"intro": ["A visitor. The boat still floats, then.", "Marrow. I keep the isle and the isle keeps me. I was at the Academy, once, before the Quiet. I taught Alder to count.", "There is a lantern here that has not been lit in nine years. I could not. Perhaps you can."],
		"chat": ["The lake is deep in the middle. I have seen what lives there. It is shy.", "Seraphine still waves from the tower some nights. I wave back. Neither of us can see the other.", "Herons nest here in spring. They do not mind me. I am furniture.", "The Watchtower was watching the lake, you know. Not the road.", "The lantern here wants the Watchtower lit first. Lanterns are sentimental about order.", "Seraphine's small star is real. I taught her to measure. I did not teach her to hope; she had that already.", "Wennet in the Wood was the Watchman's wife. If she tells you her story, listen all the way to the end."],
		"friend": ["You may call me Marrow without the Old.", "There is a second shrine under the water. Do not go looking.", "When the Ember is whole, I will come down the hill. Tell Oriel to set a chair."],
	},

	"tobin": {
		"name": "Tobin", "role": "Student, Emberwing", "model": "Barbarian", "tint": Color(1.0, 0.6, 0.55), "scale": 0.5, "pos": Vector3(12.6, 0, -17.0), "face": 180.0, "scene": "academy",
		"color": Color(1.0, 0.6, 0.55),
		"intro": ["You're the new one! I'm Tobin. Emberwing. We're the brave ones, mostly by accident.", "Alder says I Kindle too hard. I say the brazier was asking for it."],
		"chat": ["Flamecraft is the best lesson. Everything else is just waiting for Flamecraft.", "I bet Lark you'd get sorted Tidewatch. If you did, I owe her a Warmth Tonic.", "The Duelling Club with Sir Pellam is the only thing I'm top of. Don't tell Fen.", "If you find the star shards, Seraphine gives you a look. Just a look. It's worth it."],
		"friend": ["You'd have made a good Emberwing. Or you did. Either way.", "Next drill, we duel for real. Kindle only. No hard feelings.", "You're alright. For a wizard."],
		"schedule": [[8.0, 11.0, Vector3(14.4, 0, -1.5), 90.0], [11.0, 14.0, Vector3(-16.0, 0, -1.5), 270.0], [14.0, 17.0, Vector3(-3.0, 0, -19.0), 0.0], [17.0, 19.0, Vector3(-5.8, 0, -7.5), 90.0], [19.0, 21.0, Vector3(-10.0, 0, -18.0), 180.0], [21.0, 24.0, Vector3(2.0, 0, -32.5), 180.0]],
	},
	"lark": {
		"name": "Lark", "role": "Student, Tidewatch", "model": "Rogue", "tint": Color(0.6, 0.75, 1.0), "scale": 0.5, "pos": Vector3(9.6, 0, -17.0), "face": 180.0, "scene": "academy",
		"color": Color(0.6, 0.75, 1.0),
		"intro": ["Hello. Lark, Tidewatch. I take the notes everyone borrows.", "Hatch is my uncle. The leaky boat is a family tradition."],
		"chat": ["Herbology is at eleven. Isolde will ask about Moonpetal. It opens in darkness. You're welcome.", "Tidewatch has the most Order points because we actually go to Assembly.", "Quill lets me shelve books. It's the best job in the school. Don't tell Ivy.", "Somebody keeps lighting the Trial Field braziers before I get there. Is it you? It's you."],
		"friend": ["You can borrow my notes. Nobody else gets the real ones.", "When the Watchtower is lit, Uncle Hatch says he'll row us out to see it from the lake.", "You keep your promises. That's the whole of Tidewatch, really."],
		"schedule": [[8.0, 11.0, Vector3(13.0, 0, -0.5), 90.0], [11.0, 14.0, Vector3(-14.4, 0, -1.0), 270.0], [14.0, 17.0, Vector3(0.0, 0, -18.5), 0.0], [17.0, 19.0, Vector3(5.8, 0, -7.5), 270.0], [19.0, 21.0, Vector3(-14.5, 0, -18.0), 180.0], [21.0, 24.0, Vector3(-2.5, 0, -32.5), 180.0]],
	},
	"fen": {
		"name": "Fen", "role": "Student, Thornhollow", "model": "Rogue_Hooded", "tint": Color(0.6, 0.9, 0.6), "scale": 0.5, "pos": Vector3(15.6, 0, -17.0), "face": 180.0, "scene": "academy",
		"color": Color(0.6, 0.9, 0.6),
		"intro": ["Mm. Fen. Thornhollow. I'm growing something in the greenhouse that Isolde doesn't know about yet.", "It's fine. It's probably fine."],
		"chat": ["Verdant once a day per bed. Twice and the plant sulks for a week. Ask me how I know.", "Potions at seven. Corvin counts the bottles. He always counts the bottles.", "Thornhollow motto: everything grows if you stay. So I stay. Mostly in the greenhouse.", "The sheep at Ashford like Whisperleaf. The sheep at Ashford like everything."],
		"friend": ["The thing in the greenhouse is a blue Moonpetal. Isolde's old root. I think it's going to flower.", "If you ever want a quiet lesson, come to Herbology and just sit. Isolde won't mind.", "You're patient. That's rarer than brave."],
		"schedule": [[8.0, 11.0, Vector3(15.8, 0, -1.5), 90.0], [11.0, 14.0, Vector3(-12.8, 0, -1.5), 270.0], [14.0, 17.0, Vector3(3.0, 0, -19.0), 0.0], [17.0, 19.0, Vector3(-5.8, 0, -4.5), 90.0], [19.0, 21.0, Vector3(-12.0, 0, -16.5), 180.0], [21.0, 24.0, Vector3(0.5, 0, -33.5), 180.0]],
	},
	"ivy": {
		"name": "Ivy", "role": "Student, Moonquill", "model": "Rogue", "tint": Color(1.0, 0.9, 0.55), "scale": 0.5, "pos": Vector3(11.0, 0, -15.0), "face": 180.0, "scene": "academy",
		"color": Color(1.0, 0.9, 0.55),
		"intro": ["Question: why does the shrine candle never go out? Nobody knows. That's my favourite kind of question.", "Ivy. Moonquill. We ask the question nobody else will, and then usually a second one."],
		"chat": ["Lore at two. Quill will ask who built the first tower. Ashen Vale. Everyone forgets it's a person.", "The Order board is rigged. I've checked. It isn't. I've checked again.", "Astronomy is at nine. Bring something warm; the tower has no roof, which is the point.", "Why is the lake deeper than it should be? Marrow knows. Marrow won't say. That's two questions."],
		"friend": ["I wrote down every question you've asked since you arrived. Forty-one. Good ones.", "Seraphine's small star is real. I did the maths with her. It's getting closer.", "Moonquill would have taken you, you know. But then, so would everyone."],
		"schedule": [[8.0, 11.0, Vector3(13.0, 0, -6.5), 90.0], [11.0, 14.0, Vector3(-13.0, 0, -6.5), 270.0], [14.0, 17.0, Vector3(1.5, 0, -17.5), 0.0], [17.0, 19.0, Vector3(5.8, 0, -4.5), 270.0], [19.0, 21.0, Vector3(-14.0, 0, -22.5), 0.0], [21.0, 24.0, Vector3(-1.5, 0, -30.0), 180.0]],
	},

	"wennet": {
		"name": "Wennet the Grey", "role": "Ghost of the Hollow Wood", "model": "Rogue_Hooded", "tint": Color(0.75, 0.85, 0.95, 0.55), "pos": Vector3(-60.0, 0, -58.0), "face": 120.0, "scene": "village", "night_only": true, "ghost": true,
		"color": Color(0.8, 0.9, 1.0),
		"intro": ["Oh. A living one. Mind the roots; they are older than manners.", "Wennet. I kept the Watchtower with my husband, before. I am still keeping something. I forget what.", "The purple flowers are Nightcap. Pick them after dark and bring me two, with a Moonpetal, and I will teach you the draught we used to make for the long watches."],
		"chat": ["The Wood is not haunted. It is attended. There is a difference.", "I hear the Watchtower some nights. It is a kind sound.", "The graves here have no names. I knew every one of them. I will tell you, if you stay a while.", "Marrow came through once, years ago. He said hello. Nobody says hello."],
		"friend": ["You come back. The living rarely come back.", "If the fire on the tower is yours, then thank you. I can rest a little more now.", "When you light the last lantern, I will go up the hill one more time. Do not be sad; I will be glad."],
		"schedule": [],
	},

	"dilly": {
		"name": "Dilly", "role": "Fernmoor baker", "model": "Barbarian", "tint": Color(1.0, 0.85, 0.7), "scale": 0.55, "pos": Vector3(-64.0, 0, 40.0), "face": 90.0, "scene": "village",
		"color": Color(1.0, 0.9, 0.75),
		"intro": ["Bread! No? Fine. Dilly. I bake for Fernmoor, which is nine people and Hatch, who counts double.", "Bring me a Reed Perch and a Whisperleaf one day and I'll show you the one thing I do better than bread."],
		"chat": ["Hatch says the bridge is crooked on purpose. I say he's never carried a tray across it.", "The oven's the only thing in Fernmoor that didn't go out on the Quiet Night. Nobody talks about that. I do.", "Pip walks all the way over the bridge for one roll. I give him two.", "Wren's noon round ends here. She eats standing up. Couriers."],
		"friend": ["You can have the end slice. Nobody gets the end slice.", "If the Academy ever wants bread, I want it in writing.", "Fernmoor would keep you, you know. Quietly. That's how we do everything."],
		"schedule": [[12.0, 13.0, Vector3(-56.0, 0, 44.0), 200.0], [19.0, 21.5, Vector3(-66.0, 0, 48.0), 0.0]],
	},

	"ashen_portrait": {"name": "Ashen Vale (portrait)", "role": "Founder", "model": "Rogue_Hooded", "tint": Color(0.9, 0.8, 0.6), "pos": Vector3.ZERO, "face": 0.0, "scene": "portrait", "hidden": true, "color": Color(1.0, 0.85, 0.5), "intro": [], "chat": [], "friend": []},
	"garrow_portrait": {"name": "Sir Garrow (portrait)", "role": "First Gatekeeper", "model": "Knight", "tint": Color(0.8, 0.8, 0.9), "pos": Vector3.ZERO, "face": 0.0, "scene": "portrait", "hidden": true, "color": Color(0.8, 0.85, 1.0), "intro": [], "chat": [], "friend": []},
	"mael_portrait": {"name": "Mael Lowe (portrait)", "role": "Stargazer", "model": "Rogue", "tint": Color(0.6, 0.65, 0.9), "pos": Vector3.ZERO, "face": 0.0, "scene": "portrait", "hidden": true, "color": Color(0.7, 0.75, 1.0), "intro": [], "chat": [], "friend": []},
}

## Talking portraits in the great hall: [npc id for the bust, title, lines]
const PORTRAITS := [
	["ashen_portrait", "Ashen Vale, Founder", ["You are standing on my hill. Everyone is. I do not mind.", "The lantern in the window was for travellers. The school was an accident. A good one.", "Light the lanterns. That is the whole curriculum, really. The rest is detail.", "The shrine candle is mine. Do not let anyone tell you it is a miracle. It is stubbornness."]],
	["garrow_portrait", "Sir Garrow, First Gatekeeper", ["Forty years and I never closed the gate once. Pellam keeps it oiled. Good lad.", "A gate is a promise that someone is coming. Keep promising.", "If you have not drilled with Pellam, drill with Pellam. I cannot, I am paint.", "Stand straighter. No, straighter. There."]],
	["mael_portrait", "Mael Lowe, Stargazer", ["I charted the Crooked Bridge from the roof in my nightgown. It was cold. It was worth it.", "My granddaughter measures the small star every night. Tell her I am proud, and that the nightgown is in the trunk.", "The Wheel turns once a year. The valley turns with it. Nobody notices but us.", "Midnight is not late. Midnight is when the sky starts."]],
]

const EMBER_GATE := 12   # Ember needed to open the Academy gate

## Spells taught at the Academy. key: hotkey number.
const SPELLS := {
	"kindle": {"name": "Kindle", "key": 1, "color": Color(1.0, 0.75, 0.35), "blurb": "Lights a dark lantern. Each lantern lit warms the village Ember."},
	"verdant": {"name": "Verdant", "key": 2, "color": Color(0.5, 1.0, 0.6), "blurb": "Hurries a herb bed along one growth stage. Once per bed per day."},
	"glimmer": {"name": "Glimmer", "key": 3, "color": Color(0.75, 0.85, 1.0), "blurb": "A bright light on your staff for a minute. After dark it reveals the star shards hidden around the valley."},
	"mend": {"name": "Mend", "key": 4, "color": Color(1.0, 0.65, 0.85), "blurb": "Repairs a broken fence, post or lantern nearby. Each repair warms the Ember."},
}

## Academy chapter quest: light the dark lanterns of Hollowmere.
const DARK_LANTERNS := 4   # village lanterns for Chapter 2 (the isle lantern is extra)
const PAGES_TOTAL := 3


## Districts of Hollowmere (signposts + landmark text).
const DISTRICTS := {
	"tavern": {"name": "The Lantern & Ladle", "pos": Vector3(-44, 0, -1), "text": "Hollowmere's tavern, at the west end of Hearth Row. Evenings, the whole village is in here telling the same stories louder. Bramble keeps the fire; Tamsin keeps the tab."},
	"hearth": {"name": "Hearth Row", "pos": Vector3(-35, 0, -9), "text": "Where Hollowmere sleeps. Five cottages, one well, a great deal of washing. Wren, Mirabel, Bramble and Pip, Sir Pellam, Tamsin and Gorrin all come home here after dark."},
	"market": {"name": "Lantern Market", "pos": Vector3(31, 0, -9), "text": "Three stalls and a forge on the lake road. Tamsin buys potions and sells herbs (8:00-18:00). Gorrin's bench sells decorations for the village. Wren and Bramble trade here in the mornings."},
	"green": {"name": "Festival Green", "pos": Vector3(2, 0, 28), "text": "The village plays here: the maypole, the lily pond with its stepping stones, and Gorrin's Spark Targets. Villagers gather on the green in the late afternoon; Pip is always at the targets."},
	"ashford": {"name": "Ashford", "pos": Vector3(36, 0, -36), "text": "Three yellow houses, a windmill and Nell's six sheep on the Watchtower road. Wool goes down the hill; gossip comes up."},
	"wood": {"name": "The Hollow Wood", "pos": Vector3(-62, 0, -62), "text": "Dead trees, old graves and a mist that never quite lifts, north-west beyond the Trial Field. Nightcap grows here and nowhere else, and only opens after dark. Something grey walks here at night. It is polite."},
	"isle": {"name": "Heron Isle", "pos": Vector3(66, 0, 14), "text": "A green knuckle in the middle of Lake Mirren, reached by Hatch's leaking boat from the dock. Old Marrow lives here with the herons and a lantern that has been dark for nine years."},
	"trial": {"name": "Trial Field", "pos": Vector3(-30, 0, -32), "text": "The Academy's practice yard below the hill. Three cold braziers for Kindle, three tired herb beds for Verdant. Every brazier lit and every bed hurried earns a Mark. Resets each morning. Sir Pellam drills here after lunch."},
}

## Academy timetable. Lessons are taught in their hour window; each earns Marks once per day.
const LESSONS := {
	"flame": {"name": "Flamecraft", "teacher": "alder", "room": "Hall of Flame", "start": 8.0, "end": 11.0,
		"quiz": [
			["Kindle is, above all, about...", ["Anger", "Attention", "Volume"], 1],
			["A lantern lit by Kindle...", ["Goes out at dawn", "Never quite goes out", "Burns the post"], 1],
			["How many lanterns went dark in Hollowmere?", ["Two", "Four", "Nine"], 1],
		]},
	"herb": {"name": "Herbology", "teacher": "isolde", "room": "Greenhouse", "start": 11.0, "end": 14.0,
		"quiz": [
			["Which herb opens only in darkness?", ["Emberroot", "Whisperleaf", "Moonpetal"], 2],
			["Which herb is warm to the touch?", ["Emberroot", "Moonpetal", "Whisperleaf"], 0],
			["Verdant may be cast on a bed...", ["Once per day", "Three times an hour", "Only at night"], 0],
		]},
	"lore": {"name": "Lore of Ashenvale", "teacher": "quill", "room": "Library", "start": 14.0, "end": 17.0,
		"quiz": [
			["Who built the first tower on the hill?", ["Oriel Vance", "Ashen Vale", "Archivist Quill"], 1],
			["The only light that survived the Quiet Night was...", ["The shrine candle", "The forge", "The lighthouse"], 0],
			["The village Ember is...", ["A stone", "A sum of kind deeds and lit lanterns", "A kind of bird"], 1],
		]},
	"assembly": {"name": "Evening Assembly", "teacher": "oriel", "room": "Great Hall", "start": 17.0, "end": 19.0, "quiz": []},
	"potions": {"name": "Potions", "teacher": "corvin", "room": "Potions Dungeon", "start": 19.0, "end": 21.0,
		"quiz": [
			["A Warmth Tonic needs...", ["Two Emberroot", "Two Moonpetal", "One of each herb"], 0],
			["Which potion brightens a lantern?", ["Dream Draught", "Starlight Potion", "Warmth Tonic"], 1],
			["Before stirring an angry brew, you should...", ["Shout at it", "Breathe", "Add more Emberroot"], 1],
		]},
	"astronomy": {"name": "Astronomy", "teacher": "seraphine", "room": "Astronomy Tower", "start": 21.0, "end": 24.0,
		"quiz": [
			["The constellation shaped like a crooked span of stones is...", ["The Crooked Bridge", "Ashen's Wheel", "The Lantern-Bearer"], 0],
			["Who is the Lantern-Bearer named after?", ["Hatch", "Ashen Vale", "Sir Pellam"], 1],
			["On the Quiet Night the stars were...", ["Hidden", "Brighter than ever", "Red"], 1],
		]},
}

## The four Orders of Ashenvale (sorting ceremony on first entry).
const ORDERS := {
	"emberwing": {"name": "Emberwing", "virtue": "courage", "color": Color(0.95, 0.35, 0.3), "banner": "red", "motto": "Walk toward the dark with a light."},
	"tidewatch": {"name": "Tidewatch", "virtue": "loyalty", "color": Color(0.4, 0.6, 1.0), "banner": "blue", "motto": "The river keeps what it is given."},
	"thornhollow": {"name": "Thornhollow", "virtue": "patience", "color": Color(0.45, 0.85, 0.5), "banner": "green", "motto": "Everything grows if you stay."},
	"moonquill": {"name": "Moonquill", "virtue": "curiosity", "color": Color(1.0, 0.85, 0.4), "banner": "yellow", "motto": "Ask the question nobody else will."},
}
const SORTING := [
	["A lantern goes dark on the far side of the river at midnight. You...", [["Cross the bridge now, alone.", "emberwing"], ["Wake Hatch; two go safer.", "tidewatch"], ["Wait for dawn and bring the right tools.", "thornhollow"], ["Wonder why it went dark at all.", "moonquill"]]],
	["Mirabel's margin note might be wrong. You...", [["Brew it anyway and see.", "emberwing"], ["Ask her first.", "tidewatch"], ["Grow the herbs again and test slowly.", "thornhollow"], ["Read every other margin in the library.", "moonquill"]]],
	["Pip wants to see a spell. The spell is not safe for a child. You...", [["Show a smaller one, carefully.", "emberwing"], ["Promise to show him when he is older, and keep it.", "tidewatch"], ["Teach him to grow Moonpetal instead.", "thornhollow"], ["Explain exactly why it is not safe.", "moonquill"]]],
	["What did the Quiet Night take?", [["Something we can take back.", "emberwing"], ["People. The village kept the rest.", "tidewatch"], ["Time. It grows back.", "thornhollow"], ["Nobody knows yet, and that matters.", "moonquill"]]],
]

## Constellations over Ashenvale (Astronomy / Chapter 4).
const CONSTELLATIONS := {
	"bearer": {"name": "The Lantern-Bearer", "text": "Seven stars in the north, shaped like a figure holding up a light. Named for Ashen Vale, who lit the first lantern on the hill.", "stars": [Vector2(0, 0), Vector2(0.4, -1.2), Vector2(0.9, -2.3), Vector2(1.6, -2.0), Vector2(-0.3, -2.0), Vector2(-0.9, -0.8), Vector2(1.9, -3.1)]},
	"bridge": {"name": "The Crooked Bridge", "text": "A low arc of nine stars over the eastern hills. Every third star sits a little off the line, like the stones of Hatch's father's bridge.", "stars": [Vector2(-3, 0.2), Vector2(-2.2, -0.5), Vector2(-1.4, -0.7), Vector2(-0.7, -1.1), Vector2(0, -0.9), Vector2(0.8, -1.0), Vector2(1.5, -0.5), Vector2(2.3, -0.6), Vector2(3, 0.3)]},
	"wheel": {"name": "Ashen's Wheel", "text": "Eight stars in a ring high overhead. The old almanac says the Wheel turns once a year, and that the Ember of a village is brightest when the Wheel stands upright at midwinter.", "stars": [Vector2(0, -1.4), Vector2(1, -1), Vector2(1.4, 0), Vector2(1, 1), Vector2(0, 1.4), Vector2(-1, 1), Vector2(-1.4, 0), Vector2(-1, -1)]},
}

## Star shards: hidden until Glimmer is cast after dark. Each is a Mark and a few coins.
const SHARDS := {
	"shard_lake": Vector3(44.0, 0, 28.0), "shard_bridge": Vector3(-38.0, 0, 36.0), "shard_ruins": Vector3(62.0, 0, -50.0),
	"shard_fernmoor": Vector3(-66.0, 0, 52.0), "shard_tower": Vector3(-16.0, 0, -16.0), "shard_green": Vector3(-6.0, 0, 36.0),
	"shard_trial": Vector3(-40.0, 0, -36.0), "shard_hearth": Vector3(-36.0, 0, 4.0),
}

## Sky lanterns: ten paper lanterns drifting high over the valley, for broom riders.
const SKY_LANTERNS := {
	"sky_square": Vector3(0, 16, 0), "sky_academy": Vector3(4, 24, -34), "sky_lake": Vector3(58, 14, 14), "sky_isle": Vector3(66, 20, 14),
	"sky_fernmoor": Vector3(-58, 15, 46), "sky_ashford": Vector3(36, 17, -36), "sky_watchtower": Vector3(56, 26, -56), "sky_wood": Vector3(-62, 18, -62),
	"sky_bridge": Vector3(-40, 13, 31), "sky_green": Vector3(2, 22, 28),
}

## Things the Quiet Night broke. Mend fixes them (model swap).
const BROKEN := [
	{"id": "fence_hearth_1", "pos": Vector3(-20.0, 0, -12.0), "broken": "halloween/fence_seperate_broken.gltf", "fixed": "halloween/fence_seperate.gltf", "scale": 1.0},
	{"id": "fence_hearth_2", "pos": Vector3(-50.0, 0, -6.0), "broken": "halloween/fence_broken.gltf", "fixed": "halloween/fence.gltf", "scale": 1.0},
	{"id": "post_market", "pos": Vector3(24.0, 0, -16.0), "broken": "halloween/fence_pillar_broken.gltf", "fixed": "halloween/post_lantern.gltf", "scale": 1.0},
	{"id": "fence_trial", "pos": Vector3(-18.0, 0, -36.0), "broken": "halloween/fence_seperate_broken.gltf", "fixed": "halloween/fence_seperate.gltf", "scale": 1.0},
	{"id": "post_green", "pos": Vector3(14.0, 0, 22.0), "broken": "halloween/fence_pillar_broken.gltf", "fixed": "halloween/post_lantern.gltf", "scale": 1.0},
	{"id": "fence_fernmoor", "pos": Vector3(-48.0, 0, 52.0), "broken": "halloween/fence_broken.gltf", "fixed": "halloween/fence.gltf", "scale": 1.0},
	{"id": "fence_lake", "pos": Vector3(36.0, 0, 2.0), "broken": "halloween/fence_seperate_broken.gltf", "fixed": "halloween/fence_seperate.gltf", "scale": 1.0},
	{"id": "post_ruins", "pos": Vector3(50.0, 0, -60.0), "broken": "halloween/fence_pillar_broken.gltf", "fixed": "halloween/post_lantern.gltf", "scale": 1.0},
]

## What each villager loves as a gift (friendship +3; anything else +1). One gift per villager per day.
const FAVOURITES := {"wren": "tonic", "mirabel": "whisperleaf", "bramble": "perch", "pellam": "potion", "pip": "pumpkin", "hatch": "moonfish", "tamsin": "elixir", "gorrin": "emberroot", "nell": "draught", "marrow": "moonpetal", "wennet": "shade", "dilly": "perch", "oriel": "elixir", "alder": "emberroot", "isolde": "moonpetal", "quill": "draught", "corvin": "potion", "seraphine": "moonfish"}

## Things you can ask anyone about: the Quiet Night, and their work.
const ASK := {
	"wren": {"quiet": "I was twelve. The lanterns went out one by one up the hill like someone blowing out a row of candles. I finished the run anyway. You don't drop the post.", "work": "Courier. Hollowmere, Fernmoor, Ashford, the Academy when the gate's open. My legs are the economy."},
	"mirabel": {"quiet": "Every flame. Even the one under my cauldron. I sat in the dark with three beds of herbs and decided that if nothing else, those would live.", "work": "Herbalist, apothecary, and the person everyone tells their symptoms to at the market. The last one is unpaid."},
	"bramble": {"quiet": "I was out at the woodpile. Didn't see it go. Came in and the whole house was dark and Pip was asleep in the middle of it, fine. That's Pip.", "work": "Wood. Cutting it, stacking it, hauling it. Tamsin takes half. The Academy used to take the other half."},
	"pellam": {"quiet": "I was at the gate. The torches on either side went out together, like they'd agreed. I stood there till dawn. Nobody came through. Nobody has since, till you.", "work": "Gatekeeper of Ashenvale. Thirty years. Twenty-one of them with something to keep."},
	"pip": {"quiet": "I was a BABY. I don't remember. Dad says I slept through it. I would NOT sleep through it now.", "work": "I'm not allowed to have a job. I carry the small letters for Wren. That's not a job. It's a FAVOUR."},
	"hatch": {"quiet": "The river went quiet too. No, really: the water stopped talking for a night. Fernmoor noticed. Fernmoor notices everything and says nothing.", "work": "Ferryman with no ferry. The boat does. I keep the bridge, the well, and the gossip."},
	"tamsin": {"quiet": "The stall was shut; I was at the tavern. The lamps went out and the whole room went very polite. Nobody wanted to be the first to say it.", "work": "Grocer. Herbs in, potions out. I know what every house in the valley eats, and I don't tell."},
	"gorrin": {"quiet": "The forge went cold. Sixty years it had burned. I sat with it till morning like you'd sit with someone sick. Mirabel's tonic brought it back.", "work": "Smith. Lanterns, hinges, rivets, and now brooms, apparently. Iron doesn't care what it becomes."},
	"nell": {"quiet": "The sheep lay down facing the Academy an hour before. All six. Then the windmill turned backwards once. Then the dark.", "work": "Shepherd. Six sheep, one hill, a lot of weather. Wool goes to Tamsin, gossip comes back."},
	"marrow": {"quiet": "I was in the library. I had just told a student that nothing in this valley could surprise me. The candle went out in my hand. I left the next morning.", "work": "Hermit. It is harder than it looks. The herons supervise."},
	"alder": {"quiet": "The brazier in my own hall died while I was teaching. Twelve students watched me fail to relight it. Eleven of them left that week.", "work": "Flamecraft. Kindle first, then the rest. Attention is the whole subject."},
	"isolde": {"quiet": "The greenhouse went dark and every Moonpetal closed at once, at the wrong hour. They opened again at dawn as if nothing had happened. Plants are better at this than we are.", "work": "Herbology and the greenhouse. I keep what grows and teach what listens."},
	"quill": {"quiet": "Three pages out of the window. I chased them down the hill in slippers. I have told everyone I lost them on purpose. That was a lie, and then it was true.", "work": "Archivist. The library, the catalogue, the Restricted Shelves, and the cat that is not mine."},
	"corvin": {"quiet": "A cauldron that has boiled for two hundred years went still. I put my hand on it. Cold. I have never told the students that I wept.", "work": "Potions. Evenings. I count bottles. I am told this is a personality."},
	"seraphine": {"quiet": "The stars were brighter than I have ever seen them. As if something had been taken from below and given to above. I began measuring the next night.", "work": "Astronomy. Three constellations, one small star, and a roof I had removed on purpose."},
	"dilly": {"quiet": "The oven went out with everything else. Except one coal. I found it at dawn, blew on it like a fool, and here we are.", "work": "Baker. Bread, rolls, the occasional pie when someone brings fish. Nine customers and a courier."},
	"wennet": {"quiet": "I was there. I was holding his hand. I did not let go to feed the fire. I have never once been sorry, and I have never once forgiven myself.", "work": "I keep the Wood. The Wood keeps me. We have an understanding about the graves."},
	"tobin": {"quiet": "I was three. I remember the dark being warm, which Lark says is impossible.", "work": "Student. Emberwing. I'm top of Duelling and bottom of everything with reading."},
	"lark": {"quiet": "Uncle Hatch says the river stopped. I believe him. I believe most things Uncle Hatch says, which Ivy says is my whole problem.", "work": "Student. Tidewatch. Notes, shelving, and keeping Tobin out of the greenhouse."},
	"fen": {"quiet": "Mm. The seedlings in my mother's window died that night and came back in spring. I was two. I don't remember. I remember the spring.", "work": "Student. Thornhollow. I grow things. One of them is a secret."},
	"ivy": {"quiet": "Question: if every flame went out at once, what was the flame that noticed first? Answer: the shrine candle, which didn't. That's not an answer. I'm working on it.", "work": "Student. Moonquill. I ask. Forty-one so far. Quill is counting."},
}

## Birthdays (day of month). On the day: a gift counts triple and the Gazette mentions it.
const BIRTHDAYS := {"wren": 3, "mirabel": 7, "bramble": 11, "pellam": 14, "pip": 17, "hatch": 19, "tamsin": 22, "gorrin": 25, "nell": 27, "marrow": 29, "dilly": 9, "oriel": 1, "alder": 5, "isolde": 13, "quill": 16, "corvin": 21, "seraphine": 24, "tobin": 2, "lark": 8, "fen": 12, "ivy": 26}

func birthday_today() -> Array:
	var d := int(today_key().get_slice("-", 2))
	var out := []
	for id in BIRTHDAYS:
		if BIRTHDAYS[id] == d:
			out.append(id)
	return out

## A private story each villager tells once, when you become close friends (friendship 7+).
const MEMORIES := {
	"wren": "I was twelve on the Quiet Night. I was carrying the last letter up the hill when every lantern went out at once. I finished the run in the dark, by feel. The Headmistress still has that letter. She never opened it. I think she's waiting for the light to come back first.",
	"mirabel": "Corvin asked me to stay at the Academy. I said the village needed a herbalist more than the school needed another clever girl. I was right. I was also running away from him, a little. Tell him the roses survived. He'll know what I mean.",
	"bramble": "Pip's mother left the spring after the Quiet. Not died. Left. People think I don't talk about it because it hurts. I don't talk about it because Pip listens through walls. He's happy. That's the whole job.",
	"pellam": "I was Gatekeeper for thirty years and the gate was open for twenty-one of them. Nine years of guarding a door nobody can open. You'd think a knight would resent that. I just kept it oiled.",
	"pip": "I saw the light in the Academy the night before you came. Nobody believes me. It was in the tower window and it went blink-blink-blink, like somebody saying hello. I waved. Don't tell Dad I was out.",
	"hatch": "My father built the bridge crooked on purpose so that anyone crossing it at night would have to slow down and look at the water. 'Nobody drowns who is looking,' he said. He was wrong about one thing, once. I don't cross it at night.",
	"tamsin": "I came to Hollowmere for one market season, twenty years ago, to sell a cart of apples. The cart broke on the Fernmoor road. Hatch fixed it. By the time it was fixed I'd met everyone, and nobody in the world was waiting for me anywhere else.",
	"gorrin": "The night the forge went cold I sat in front of it till dawn, like you'd sit with someone sick. In the morning Mirabel brought a Warmth Tonic and poured it on the coals. It should not have worked. It did. Don't tell Corvin.",
	"nell": "The sheep know when a storm is coming, and they knew the Quiet Night. All six lay down facing the Academy an hour before it happened. I've never told anyone that. It sounds mad. It is mad. They did it again last week.",
	"marrow": "I taught Alder to count, and Oriel to lie convincingly, and Seraphine to wait. Then the light went out and I found I had taught myself nothing. So I came here, to learn from the herons. They are very patient teachers.",
	"oriel": "I have a letter on my desk that Wren carried up the hill on the Quiet Night. It is addressed to the Headmistress. I have been Headmistress for nine years and I have not opened it. When the Watchtower burns, I will. You may be there.",
	"alder": "I set fire to the Hall of Flame once, as a student. Properly. The whole east wing. Marrow put it out with a bucket and a word, and then made me rebuild the brazier by hand. It is the one you practise on. Every lantern I light, I light with that bucket in mind.",
	"isolde": "Mirabel and I bred the first blue Moonpetal in this greenhouse. We were nineteen. She took the cutting down the hill and I kept the root. They are the same plant. They have been apart for forty years and they still open at the same minute.",
	"quill": "On the Quiet Night I was in the library. Three pages blew out of the window and I chased them down the hill in my slippers and lost them in the dark. I have told everyone I lost them on purpose, so the village would have something to find. That was a lie. It was also, it turns out, true.",
	"corvin": "I keep a bottle on the top shelf with no label. It is the Warmth Tonic Mirabel made the morning after the Quiet, the one that relit Gorrin's forge. Half of it is gone. I have never dared drink the rest. Tell her it is still there.",
	"dilly": "I came to Fernmoor with a cart of flour and a man who said he'd stay. The flour stayed. I built the oven around the one coal that was still warm the morning after the Quiet. It has never gone out since, and I have never once told anyone why I keep it that way.",
	"wennet": "I was the one who let the fire go out. Not from carelessness; I was holding my husband's hand, and I did not let go to feed it. I have never regretted it, and I have never forgiven myself, and I have found those two can live in one house quite comfortably.",
	"seraphine": "There is a small star just left of the Lantern-Bearer that was not there before the Quiet Night. I have measured it every clear night for nine years. It is getting closer. I do not think it is coming to hurt us. I think it is coming home.",
}

## Founders' Cards: twelve collectible cards hidden in chests across the valley.
const CARDS := {
	"ashen": {"name": "Ashen Vale", "text": "Built the first tower on the hill and lit a lantern in its window so travellers could find her. The lantern became the shrine candle. The tower became a school.", "pos": "the witch's tower in Hollowmere"},
	"first_keeper": {"name": "Sir Garrow, First Gatekeeper", "text": "Guarded the Academy gate for forty years and never once closed it. Sir Pellam keeps his helmet oiled.", "pos": "Trial Field"},
	"thornquist_elder": {"name": "Old Mother Thornquist", "text": "Mirabel's grandmother. Bred Emberroot from a wild mountain weed and a great deal of shouting.", "pos": "the apothecary garden"},
	"ferryman": {"name": "Hatch the Elder", "text": "Built the crooked bridge on the Fernmoor road. Every third stone sits off the line so that crossers slow down and look at the water.", "pos": "Fernmoor's well"},
	"shepherd": {"name": "Wyn of Ashford", "text": "First shepherd on the hill. Claimed the sheep could predict storms. The sheep have never denied it.", "pos": "Ashford's windmill"},
	"lanternwright": {"name": "Brannoc Gorrin", "text": "Gorrin's great-grandfather, who forged the first village lanterns. The iron is still good. It was never the iron.", "pos": "the Lantern Market"},
	"heron_hermit": {"name": "The Heron Hermit", "text": "Nobody remembers her name. She rowed to the isle in the year of the long frost and taught the herons to wait. Marrow says they taught her.", "pos": "Heron Isle"},
	"watchman": {"name": "The Last Watchman", "text": "Kept the Watchtower fire until the Quiet Night, when it went out with every other flame in the valley. He walked down the hill and was never seen again. Some say he went up.", "pos": "the Old Watchtower"},
	"archivist": {"name": "Quill the First", "text": "Not our Quill. An earlier one, who catalogued the library by candlelight and lost only two pages in sixty years. Our Quill considers this unfair.", "pos": "the Academy library"},
	"stargazer": {"name": "Mael Lowe", "text": "Seraphine's grandmother. Drew the first chart of the Crooked Bridge from the tower roof, in winter, in her nightgown.", "pos": "the Astronomy Tower"},
	"brewer": {"name": "Corvin the Younger", "text": "Yes, that Corvin, aged nine, who brewed a Dream Draught in a soup pot and slept for two days. The pot is still in the dungeon.", "pos": "the Potions Dungeon"},
	"watchman_wife": {"name": "Wennet of the Watch", "text": "Kept the Watchtower fire with her husband for thirty years. The night it went out, she was holding his hand. She has not left the Wood since. She says hello, if you say it first.", "pos": "the crypt in the Hollow Wood"},
	"founder_orders": {"name": "The Four Founders", "text": "Ember, Tide, Thorn and Moon: four apprentices who argued about everything except the lantern. The Orders are named for them. The argument continues.", "pos": "the common room"},
}

## Daily Order task, set by your Order's student. Progress is counted from today's records.
const ORDER_TASKS := {
	"emberwing": {"student": "tobin", "text": "Light all three Trial Field braziers today.", "need": 3},
	"tidewatch": {"student": "lark", "text": "Fill two villagers' requests today.", "need": 2},
	"thornhollow": {"student": "fen", "text": "Cast Verdant on three beds today.", "need": 3},
	"moonquill": {"student": "ivy", "text": "Do two lesson practicals today.", "need": 2},
}

## Achievements ("Honours"), checked after notable actions.
const HONOURS := {
	"first_brew": {"name": "First Brew", "text": "Brew any potion."},
	"gate": {"name": "The Gate Opens", "text": "Open the Academy gate."},
	"sorted": {"name": "Sorted", "text": "Join an Order."},
	"four_spells": {"name": "Four Spells", "text": "Learn Kindle, Verdant, Glimmer and Mend."},
	"all_lanterns": {"name": "Lamplighter", "text": "Light every dark lantern in Hollowmere."},
	"broom": {"name": "Airborne", "text": "Buy the Ashwood broom."},
	"ten_fish": {"name": "Angler", "text": "Catch ten fish."},
	"all_cards": {"name": "Founders' Friend", "text": "Collect all thirteen Founders' Cards."},
	"all_shards": {"name": "Starlit", "text": "Find all eight star shards."},
	"all_sky": {"name": "Lantern Rider", "text": "Fly through all ten sky lanterns."},
	"all_mend": {"name": "Handy", "text": "Mend everything the Quiet Night broke."},
	"friends": {"name": "Everyone's Apprentice", "text": "Become friends with every villager."},
	"close": {"name": "Confidant", "text": "Hear five villagers' private stories."},
	"adept": {"name": "Adept", "text": "Reach the rank of Adept."},
	"mage": {"name": "Mage of Ashenvale", "text": "Reach the rank of Mage."},
	"ring": {"name": "Ring of Fires", "text": "Light Watchtower, isle and shrine together."},
	"star": {"name": "Home", "text": "See the small star come down."},
	"perfect_duel": {"name": "Unflinching", "text": "A perfect Duelling Club drill."},
	"all_recipes": {"name": "Full Pantry", "text": "Unlock every recipe."},
	"cottage": {"name": "Home Comforts", "text": "Buy every piece of cottage furniture."},
}

## Student favours: one-off side quests in the Academy.
const FAVOURS := {
	"tobin": {"text": "Beat 6 of 8 in the Duelling Club and I'll stop calling you 'new one'.", "check": "duel6", "reward": "Tobin: \"Six! Fine. Fine. You have a name now.\"  (+2 Marks, +10 coins)"},
	"lark": {"text": "I left my notes in the Restricted Shelves. If you ever get in there, bring them. Quill doesn't know. Quill must not know.", "check": "notes", "reward": "Lark: \"My notes! Quill didn't— no. Good. Thank you.\"  (+2 Marks, +10 coins)"},
	"fen": {"text": "Bring me one Nightcap from the Hollow Wood. I want to see if it will grow in a pot. It won't. I want to see.", "check": "nightcap", "reward": "Fen: \"It's sulking already. Perfect.\"  (+2 Marks, +1 Ember)"},
	"ivy": {"text": "Question forty-two: what does the shrine candle smell of? Go and find out. Properly. I'll know if you guess.", "check": "shrine", "reward": "Ivy: \"Whisperleaf and iron. I KNEW it. Forty-two.\"  (+2 Marks, +10 coins)"},
}

const RANKS := [[0, "Novice"], [6, "Initiate"], [15, "Adept"], [30, "Journeyman"], [60, "Mage"]]

## Tamsin's stall: herbs for sale, potions bought.
const SHOP_BUY := {"emberroot": 4, "whisperleaf": 4, "moonpetal": 6, "pumpkin_seed": 6}
const SHOP_SELL := {"potion": 12, "tonic": 7, "draught": 10, "elixir": 22, "minnow": 3, "perch": 6, "moonfish": 14, "oil": 16, "broth": 9, "shade": 25, "nightcap": 5, "pie": 11, "sunbell": 8, "glow": 30, "pumpkin": 12}

## Staff crystals Gorrin sells (cosmetic glow colour).
const CRYSTALS := {"blue": {"name": "Riverglass", "color": Color(0.7, 0.85, 1.0), "price": 0}, "ember": {"name": "Ember Garnet", "color": Color(1.0, 0.6, 0.35), "price": 25}, "verdant": {"name": "Thorn Jade", "color": Color(0.55, 1.0, 0.65), "price": 25}, "moon": {"name": "Moonquill Opal", "color": Color(0.95, 0.8, 1.0), "price": 25}}


func public_books_total() -> int:
	var n := 0
	for id in BOOKS:
		if not BOOKS[id].get("restricted", false):
			n += 1
	return n


func public_books_read() -> int:
	var n := 0
	for id in GameState.books_read:
		if BOOKS.has(id) and not BOOKS[id].get("restricted", false):
			n += 1
	return n


static func rank_for(marks: int) -> String:
	var r := "Novice"
	for e in RANKS:
		if marks >= e[0]:
			r = e[1]
	return r


func lesson_now() -> String:
	var h := GameState.hour_of_day()
	for id in LESSONS:
		if h >= LESSONS[id]["start"] and h < LESSONS[id]["end"]:
			return id
	return ""


const GAZETTE := [
	"Nell counted seven sheep again on Tuesday. All six deny it.",
	"Tamsin reports that nobody has tried to pay in firewood this week. Bramble disputes this.",
	"The windmill at Ashford turned backwards for one minute at dawn. Nell says the sheep were facing the Academy. Nell says a lot of things.",
	"Sir Pellam has oiled the gate hinge. Gorrin would like it noted that the hinge did not need it.",
	"Old Marrow was seen waving at the Astronomy Tower. Professor Lowe was seen waving back. Neither can see the other.",
	"A heron has nested on the dock. Hatch's boat has been moved three feet to the left as a courtesy.",
	"Archivist Quill reminds students that the library closes 'when it closes'.",
	"Pip has been banned from riding sheep. Pip has been banned from riding sheep again.",
	"The shrine candle burned blue for an hour on Sunday. Mirabel says it does that. Nobody else has ever seen it do that.",
	"Lost: one left boot, Fernmoor bridge, Tuesday night. Finder may keep the boot; Hatch would like the story.",
	"Master Corvin counted the bottles. All present. He counted again. Still present. He is unsettled.",
	"The Lantern Market will stay open late on Market Day. Gorrin will not. 'Iron sleeps,' he says.",
	"Professor Alder has set fire to nothing this week and would like credit for it.",
	"Wren ran the hill four times on Thursday and reports her legs are 'made of soup'.",
	"Fen's unidentified greenhouse plant has grown a second leaf. Professor Isolde has 'questions'.",
	"The Lantern & Ladle reports a full house every evening since the apprentice arrived. Bramble would like it known the fire was always this good.",
	"Dilly of Fernmoor has baked a pie 'for someone who brings fish'. Hatch has been seen carrying a bucket.",
]

func todays_gazette() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = today_key().hash() + 99
	var out := []
	var tries := 0
	while out.size() < 3 and tries < 20:
		var line: String = GAZETTE[rng.randi() % GAZETTE.size()]
		if not out.has(line):
			out.append(line)
		tries += 1
	return out


## Day of the week (0 = Sunday) in local time.
func weekday() -> int:
	var bias := Time.get_time_zone_from_system().get("bias", 0) as int
	return Time.get_datetime_dict_from_unix_time(int(GameState.now() + bias * 60.0)).weekday


## Today's special, if any: Market Day (Saturday, Tamsin pays half again) or Lantern Walk (Sunday evening on Festival Green).
func todays_event() -> Dictionary:
	match weekday():
		6: return {"id": "market", "name": "Market Day", "text": "Tamsin pays 50% more for everything you sell today. Pumpkin contest at the judging table on Festival Green."}
		0: return {"id": "lantern", "name": "Lantern Walk", "text": "From 19:00 the village walks the green with lanterns. Join them for Ember."}
	return {}


## Season from the real month: winter, spring, summer, autumn.
func season() -> String:
	var bias := Time.get_time_zone_from_system().get("bias", 0) as int
	var m: int = Time.get_datetime_dict_from_unix_time(int(GameState.now() + bias * 60.0)).month
	if m in [12, 1, 2]: return "winter"
	if m in [3, 4, 5]: return "spring"
	if m in [6, 7, 8]: return "summer"
	return "autumn"


## Weather for today, deterministic by date: clear, misty, or rain (snow in winter).
func weather() -> String:
	var r := RandomNumberGenerator.new()
	r.seed = (today_key() + "weather").hash()
	var v := r.randf()
	if v < 0.55: return "clear"
	if v < 0.8: return "misty"
	return "snow" if season() == "winter" else "rain"


## Today's letter, chosen by date; empty if already collected.
func todays_letter() -> Dictionary:
	var key := today_key()
	if GameState.last_letter_day == key:
		return {}
	var r := RandomNumberGenerator.new()
	r.seed = (key + "letter").hash()
	var l: Array = LETTERS[r.randi() % LETTERS.size()]
	return {"from": l[0], "text": l[1], "gift": l[2], "amount": l[3]}

## Request kinds a villager can post. amount in items.
const ASKS := [
	["moonpetal", 3, "Three Moonpetal, please. Pick them after dark."],
	["emberroot", 3, "I need three Emberroot before the cold sets in."],
	["whisperleaf", 3, "Three Whisperleaf for a tea I'm trying."],
	["potion", 1, "One Starlight Potion. I'd like to see a bright lantern again."],
	["tonic", 1, "A Warmth Tonic would get me through the night."],
	["draught", 1, "A Dream Draught. I have not slept well since the Quiet."],
	["minnow", 2, "Two Mirren Minnows from the dock, if the fish are biting."],
	["perch", 1, "One Reed Perch. The cat has been looking at me."],
	["emberroot", 2, "Two Emberroot. The nights are drawing in."],
	["whisperleaf", 2, "Two Whisperleaf. Ask me no questions."],
]


const HOMEWORK := [
	["emberroot", 2, "Homework: two Emberroot, for the demonstration. Fresh, not the woodpile kind."],
	["moonpetal", 2, "Homework: two Moonpetal. Picked after dark, or they are just petals."],
	["whisperleaf", 2, "Homework: two Whisperleaf. Do not tell it any lies on the way up."],
	["potion", 1, "Homework: one Starlight Potion, brewed by you. I will know."],
	["tonic", 1, "Homework: a Warmth Tonic. The tower is cold and I am old."],
]


## Today's key, e.g. "2026-10-29" in local time.
func today_key() -> String:
	var bias := Time.get_time_zone_from_system().get("bias", 0) as int
	var d := Time.get_datetime_dict_from_unix_time(int(GameState.now() + bias * 60.0))
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## Two requests per real day, chosen deterministically from the date.
func todays_requests() -> Array:
	var key := today_key()
	var seed_v := key.hash()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var ids := []
	for k in NPCS:
		if NPCS[k].get("scene", "village") == "village":
			ids.append(k)
	ids.sort()
	var out := []
	var pick := []
	var tries := 0
	while pick.size() < 2 and tries < 10:
		var who: String = ids[rng.randi() % ids.size()]
		if not pick.has(who):
			pick.append(who)
		tries += 1
	for who in pick:
		var ask: Array = ASKS[rng.randi() % ASKS.size()]
		out.append({"id": key + ":" + who, "npc": who, "item": ask[0], "amount": ask[1], "line": ask[2]})
	# Homework: one Academy teacher a day wants something brought up the hill.
	var teachers := ["alder", "isolde", "quill", "corvin", "seraphine"]
	var t: String = teachers[rng.randi() % teachers.size()]
	var hw: Array = HOMEWORK[rng.randi() % HOMEWORK.size()]
	out.append({"id": key + ":" + t, "npc": t, "item": hw[0], "amount": hw[1], "line": hw[2], "homework": true})
	return out


func request_for(npc_id: String) -> Dictionary:
	for r in todays_requests():
		if r["npc"] == npc_id and not GameState.quests_done.has(r["id"]):
			return r
	return {}


func item_name(id: String) -> String:
	if RECIPES.has(id):
		return RECIPES[id]["name"]
	return GameState.ITEM_NAMES.get(id, id)
