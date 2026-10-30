// Notes and questions for measuring how Shiv's note search ranks (#296).
//
// 14 long notes (about 1,000-2,000 characters) each carry one fact near the
// start and one near the end; 16 short notes share their topics so they
// compete with the long ones; 3 very long notes (over 5,000 characters, past
// what the 1024 Gecko file reads) hide a fact at the end. Every question names
// the note that answers it. Questions deliberately avoid the note's own wording.

typedef CorpusNote = ({String id, String text});
typedef CorpusQuestion = ({String text, String noteId, String where});

const longNotes = <CorpusNote>[
  (
    id: 'L01-espresso',
    text:
        'Dialling in espresso at home is mostly about grind size, dose and time. '
        'I start with an 18 gram dose in a double basket and aim for a 36 gram '
        'yield in 28 seconds, using water at 93 degrees Celsius. If the shot runs '
        'in 18 seconds and tastes sour and thin, the grind is too coarse and I '
        'move the grinder two steps finer. If it crawls past 40 seconds and tastes '
        'bitter and dry, I go two steps coarser.\n\n'
        'Fresh beans matter more than the machine. Beans are at their best between '
        'five and twenty days after roasting; before that they release too much '
        'carbon dioxide and the crema looks foamy and uneven. I keep the bag '
        'sealed, store it in a cupboard away from the stove and never in the '
        'freezer door, where moisture sneaks in every time it opens.\n\n'
        'Milk is a separate craft. For a flat white I steam 150 millilitres of '
        'whole milk to about 60 degrees, stopping before it burns, and swirl the '
        'jug so the foam folds into the liquid. A thermometer clipped to the jug '
        'saved me from scalding milk for a month until my hands learned the feel.\n\n'
        'Cleaning is the boring part that decides everything else. I backflush the '
        'machine with a blind basket every Sunday, and every three months I descale '
        'it with citric acid, a tablespoon in a litre of water, running half '
        'through the group head and half through the steam wand. The shower screen '
        'gets soaked in the cafiza solution overnight.',
  ),
  (
    id: 'L02-rust',
    text:
        'Rust ownership took me a week to feel natural. Every value has exactly one '
        'owner, and when the owner goes out of scope the value is dropped. Assigning '
        'a String to another variable moves it, so the first variable can no longer '
        'be used; cheap Copy types such as integers are copied instead.\n\n'
        'Borrowing lets code use a value without taking it. You may have any number '
        'of shared references or exactly one mutable reference at a time, never '
        'both. The compiler enforces this at compile time, which is why data races '
        'cannot happen in safe Rust. When the borrow checker complains, the fix is '
        'usually to shorten how long a reference lives, not to clone everything.\n\n'
        'Lifetimes name how long references stay valid. A function returning a '
        'reference must say which input it borrows from, written like fn longest<\'a>'
        '(a: &\'a str, b: &\'a str) -> &\'a str. Most of the time the elision rules '
        'infer them and I never type an apostrophe.\n\n'
        'For shared ownership I reach for Rc in single-threaded code and Arc across '
        'threads, and I pair them with RefCell or Mutex when the data must change. '
        'Cargo builds in debug mode by default; the release profile with the '
        '--release flag turns on optimisations and is often ten to fifty times '
        'faster, so benchmarks must always use it.',
  ),
  (
    id: 'L03-marathon',
    text:
        'My marathon plan runs sixteen weeks and peaks at 72 kilometres. Monday is '
        'rest, Tuesday is intervals such as six repeats of 800 metres at 10K pace '
        'with 400 metres of jogging between them, Thursday is a tempo run of '
        'thirty minutes at half marathon pace, and Sunday is the long run that '
        'grows by two kilometres a week until it reaches 32.\n\n'
        'Easy days really are easy. I keep them at a pace where I can hold a full '
        'conversation, around 6 minutes 20 per kilometre for me, and I resist the '
        'urge to race the group I meet in the park. Most injuries I have had came '
        'from running easy days too hard, not from the hard days.\n\n'
        'Fuelling is practised, not improvised. On every long run beyond 90 minutes '
        'I take 60 grams of carbohydrate an hour, one gel every 25 minutes with '
        'water, and I test the exact brand I will use on race day. The week before '
        'the race I taper to sixty percent of the volume and eat extra rice and '
        'potatoes for the last three days.\n\n'
        'On race morning I wear shoes with at least 100 kilometres in them, never '
        'new ones, and put petroleum jelly on every spot that has ever chafed. My '
        'goal is a negative split: the first half in 1:52 and the second half in '
        '1:50, finishing near 3 hours 42.',
  ),
  (
    id: 'L04-kyoto',
    text:
        'Kyoto trip notes for April. We land at Kansai airport and take the Haruka '
        'express straight to Kyoto station, about 75 minutes, and a ten day '
        'Hankyu pass is not needed because most places are reachable by bus or on '
        'foot. Our guesthouse is a machiya in the Nishijin district, a short walk '
        'from the textile centre.\n\n'
        'Day one is Fushimi Inari at sunrise before the crowds, climbing past the '
        'thousands of orange gates to the summit loop, which takes about two hours. '
        'Day two is Arashiyama: the bamboo grove early, then the monkey park, and a '
        'boat ride on the Hozu river if the weather holds. Day three is the '
        'Philosopher\'s Path ending at Nanzen-ji, with lunch of yudofu, tofu '
        'simmered in kombu broth.\n\n'
        'For food I want to try kaiseki once, ideally at a small place with a set '
        'menu around 9,000 yen, and eat cheaply the rest of the time at Nishiki '
        'market: pickles, tamagoyaki and fresh soy milk doughnuts. Many temples '
        'close at five, so evenings are for Gion and the lantern-lit Pontocho '
        'alley.\n\n'
        'Practical points: carry cash because small shops rarely take cards, buy an '
        'IC card for the buses, and book Kinkaku-ji tickets for the first slot '
        'at nine to avoid tour groups. The cherry blossoms usually peak in the '
        'first week of April.',
  ),
  (
    id: 'L05-sourdough',
    text:
        'My sourdough loaf uses 500 grams of bread flour, 375 grams of water, 100 '
        'grams of active starter and 10 grams of salt, a hydration of about 75 '
        'percent. I mix everything, rest for thirty minutes, then do four sets of '
        'stretch and folds spaced forty-five minutes apart. The dough should '
        'grow by roughly half in volume during the bulk, which takes about five '
        'hours at 24 degrees.\n\n'
        'Shaping is where the loaf gets its structure. I pre-shape into a loose '
        'round, rest ten minutes, then pull the surface tight into a batard and '
        'drop it seam side up into a floured banneton. The loaf then proves in the '
        'fridge overnight, up to sixteen hours, which also deepens the sour taste.\n\n'
        'I bake in a preheated Dutch oven at 250 degrees for twenty minutes with '
        'the lid on, then lower to 220 and bake another twenty-five minutes with '
        'the lid off until the crust is deep brown. The lid traps steam so the loaf '
        'springs up before the crust sets.\n\n'
        'If the starter smells like nail polish remover it is hungry; I feed it '
        'twice a day with equal weights of flour and water until it smells yeasty '
        'again. I keep a spare jar of dried starter flakes in case the main jar '
        'is ever lost.',
  ),
  (
    id: 'L06-index-funds',
    text:
        'My investing rules fit on one page. First an emergency fund of six months '
        'of expenses sits in a savings account, untouched. Only then do I put '
        'money into a low-cost global index fund with an expense ratio under 0.2 '
        'percent, bought on the same day each month regardless of the news.\n\n'
        'I hold roughly 80 percent equities and 20 percent bonds, and rebalance '
        'once a year in January, selling whichever part has drifted more than five '
        'points from target. Rebalancing is the only time I look at the portfolio; '
        'checking daily only invites bad decisions.\n\n'
        'Taxes can quietly eat returns. I fill the tax-advantaged retirement account '
        'first, then use the taxable account for the rest, and I avoid selling '
        'winners in the same year if a loss elsewhere can offset the gain. '
        'Dividends are reinvested automatically.\n\n'
        'Avoided mistakes: no individual stocks except a small fun budget of two '
        'percent, no leverage, no trying to time the market, and no fund with a '
        'sales charge. A decade of boring monthly deposits has beaten everything '
        'clever I tried before. I read the annual report of the fund once a year '
        'and nothing else.',
  ),
  (
    id: 'L07-tomatoes',
    text:
        'Growing tomatoes on the balcony: I start seeds indoors six to eight weeks '
        'before the last frost, in a tray on a warm shelf at 24 degrees, and move '
        'seedlings into bigger pots when the first true leaves appear. Burying the '
        'stem up to the lowest leaves makes extra roots and a sturdier plant.\n\n'
        'Indeterminate varieties such as Sungold keep growing all season and need '
        'a tall stake and regular pruning of the suckers that appear between the '
        'stem and the branches. Determinate bush types like Roma stay compact and '
        'ripen together, which is better for sauce.\n\n'
        'Water deeply but only when the top two centimetres of soil are dry; '
        'uneven watering causes blossom end rot, the black patch on the bottom of '
        'the fruit, and splitting after rain. A feed high in potassium every '
        'two weeks once flowers show helps the fruit set.\n\n'
        'Common trouble: aphids on new growth wash off with a jet of water, and '
        'yellowing lower leaves are usually just old age. I pick fruit when fully '
        'coloured and never refrigerate it, because cold kills the flavour.',
  ),
  (
    id: 'L08-moons',
    text:
        'Notes on the moons of the outer planets. Jupiter has more than ninety '
        'known moons, but four dominate: Io, Europa, Ganymede and Callisto, the '
        'Galilean moons discovered by Galileo in 1610. Io is the most volcanically '
        'active body in the solar system, with hundreds of volcanoes powered by '
        'tidal heating from Jupiter.\n\n'
        'Europa hides a salty ocean beneath an ice shell perhaps fifteen to '
        'twenty-five kilometres thick, which makes it a leading candidate in the '
        'search for life; the Europa Clipper probe launched in 2024 will make '
        'dozens of close flybys. Ganymede is the largest moon in the solar system, '
        'bigger than Mercury, and the only moon with its own magnetic field.\n\n'
        'Saturn\'s Titan is the only moon with a thick atmosphere, mostly nitrogen, '
        'with lakes of liquid methane and ethane on its surface. The Huygens probe '
        'landed there in 2005. Enceladus sprays water geysers from cracks near its '
        'south pole, and Cassini flew through the plumes and tasted organic '
        'molecules.\n\n'
        'Neptune\'s Triton orbits backwards, which suggests it was captured from the '
        'Kuiper belt, and Uranus has twenty-seven moons named after characters '
        'from Shakespeare and Pope, such as Miranda and Titania.',
  ),
  (
    id: 'L09-rome',
    text:
        'The Roman Republic was founded in 509 BC after the last king, Tarquin the '
        'Proud, was expelled, and power passed to two consuls elected each year. '
        'The Senate advised them and the tribunes of the people could veto laws, '
        'a balance that lasted nearly five hundred years.\n\n'
        'Rome\'s rise came through the Punic Wars against Carthage. Hannibal '
        'crossed the Alps in 218 BC with war elephants and won at Cannae in 216, '
        'but Scipio Africanus carried the war to Africa and defeated him at Zama '
        'in 202 BC. By 146 BC Carthage was destroyed and Rome ruled the western '
        'Mediterranean.\n\n'
        'The Republic collapsed in civil wars. Julius Caesar crossed the Rubicon '
        'in 49 BC, was named dictator for life and was stabbed by senators on the '
        'Ides of March, 44 BC. His heir Octavian defeated Antony and Cleopatra at '
        'Actium in 31 BC and in 27 BC became Augustus, the first emperor.\n\n'
        'The western empire fell in 476 AD when Odoacer deposed the boy emperor '
        'Romulus Augustulus, while the eastern half, Byzantium, survived until '
        'the Ottomans took Constantinople in 1453.',
  ),
  (
    id: 'L10-sleep',
    text:
        'What I changed to sleep better. I now go to bed and wake up at the same '
        'time every day, weekends included, because the body clock cares more '
        'about regularity than about total hours. Light is the main signal: ten '
        'minutes of outdoor daylight within an hour of waking, and dim warm lamps '
        'after eight in the evening.\n\n'
        'Caffeine has a half life of about five to six hours, so my last coffee is '
        'before noon. Alcohol knocks me out but fragments the second half of '
        'the night, so I stopped drinking on weeknights. A heavy dinner within '
        'three hours of bed also hurts, so I eat earlier.\n\n'
        'The bedroom is cool, around 18 degrees, dark and quiet, with blackout '
        'curtains and earplugs. The phone charges in the hallway; reading a paper '
        'book for twenty minutes replaced scrolling. If I cannot sleep after '
        'twenty minutes I get up and sit in dim light instead of lying there '
        'frustrated.\n\n'
        'After six weeks I fall asleep in under fifteen minutes and my watch shows '
        'about ninety minutes of deep sleep a night, up from sixty.',
  ),
  (
    id: 'L11-bike',
    text:
        'Basic bicycle maintenance I do myself. Tyre pressure first: for 28 mm '
        'road tyres I run about 5.5 bar in the rear and 5 in the front, and I check '
        'it before every ride with a floor pump because tubes lose pressure daily. '
        'A pinch flat shows as two small holes next to each other, a sign that the '
        'pressure was too low.\n\n'
        'The chain needs cleaning and fresh lube every 300 kilometres. I wipe it, '
        'apply one drop of wax lube per link, let it soak for a few minutes and '
        'wipe off the excess, because oily chains pick up grit. Replace the chain '
        'when a checker shows 0.5 percent wear, or the cassette wears out too.\n\n'
        'Brake pads wear fastest in the rain; replace them when the grooves are '
        'gone. Adjust cable tension with the barrel adjuster, and tighten the '
        'stem and seatpost bolts with a torque wrench to the number printed on '
        'the part, usually 5 to 6 newton metres for carbon.\n\n'
        'Once a year I strip the bearings in the headset and bottom bracket, '
        'clean and regrease them, and check the wheels for true by spinning them '
        'against the brake pad.',
  ),
  (
    id: 'L12-asyncio',
    text:
        'Python asyncio lets one thread juggle many waiting tasks. An async def '
        'function returns a coroutine, and nothing runs until it is awaited or '
        'scheduled; calling it just builds the object. The entry point is '
        'asyncio.run(main()), which creates the event loop, runs the coroutine and '
        'closes the loop.\n\n'
        'To run work concurrently I use asyncio.gather or, from Python 3.11, a '
        'TaskGroup, which cancels the siblings automatically if one task raises. '
        'Creating a task with create_task starts it immediately in the background, '
        'and I must keep a reference to it or the garbage collector may destroy it '
        'mid-flight.\n\n'
        'CPU-bound code blocks the loop, so a heavy loop belongs in a process '
        'pool via run_in_executor. Blocking calls such as requests.get or '
        'time.sleep freeze every task; use aiohttp and asyncio.sleep instead.\n\n'
        'Timeouts are done with asyncio.timeout, an async context manager added '
        'in 3.11, and a semaphore limits concurrency when hammering an API: I '
        'cap it at 20 simultaneous requests. Debug mode, enabled with '
        'PYTHONASYNCIODEBUG=1, logs coroutines that were never awaited.',
  ),
  (
    id: 'L13-chess',
    text:
        'Chess openings I actually play. As White I open with 1.e4 and answer the '
        'Sicilian with the Alapin, 2.c3, to avoid mountains of theory. Against '
        '1...e5 I play the Italian with 3.Bc4 and the quiet 4.c3 followed by d3, '
        'aiming for a slow game where understanding beats memory.\n\n'
        'As Black against 1.e4 I choose the Caro-Kann, 1...c6, because the bishop '
        'on c8 gets out before the pawn chain closes. Against 1.d4 I play the '
        'Queen\'s Gambit Declined, solid and with few surprises, and keep the '
        'Slav as a backup.\n\n'
        'Principles before lines: control the centre, develop knights before '
        'bishops, castle early, and do not move the same piece twice in the '
        'opening without a reason. Count attackers and defenders on a square '
        'before every capture.\n\n'
        'My weakness is time trouble. I now give myself a budget of ten minutes '
        'for the first twenty moves of a rapid game, and after every blunder I '
        'write the position into a notebook and revisit it on Sunday, which has '
        'raised my rating from 1250 to 1480 in eight months.',
  ),
  (
    id: 'L14-wifi',
    text:
        'Home network setup. The fibre modem connects to a dedicated router, '
        'with the ISP box in bridge mode so there is only one layer of NAT. The '
        'router runs on 192.168.10.0/24 with the gateway at 192.168.10.1, and DHCP '
        'hands out addresses from .100 to .199, leaving the lower range for fixed '
        'devices such as the printer and the NAS.\n\n'
        'Wi-Fi: the 5 GHz band for laptops and phones on channel 36 with an 80 MHz '
        'width, and the 2.4 GHz band for smart plugs only on channel 6. WPA3 is on '
        'where devices support it, and the guest network is isolated so visitors '
        'cannot reach the NAS. The access point sits high in the hallway, not '
        'behind the television.\n\n'
        'Security: the router admin page is reachable only from the wired '
        'network, firmware updates are automatic, and the default admin password '
        'was changed on day one. DNS goes to a filtering resolver that blocks '
        'known malware domains.\n\n'
        'For backups the NAS mirrors two disks and syncs nightly to an encrypted '
        'cloud bucket; I test a restore every quarter. A small UPS keeps the modem, '
        'router and NAS alive through short power cuts.',
  ),
];

const shortNotes = <CorpusNote>[
  (id: 'S01', text: 'Bought a burr grinder with 40 mm flat burrs for the espresso machine.'),
  (id: 'S02', text: 'Long run tomorrow: 24 km at an easy pace, bring two gels.'),
  (id: 'S03', text: 'Recipe: tomato soup with roasted garlic and basil, serves four.'),
  (id: 'S04', text: 'Call the dentist on Monday to move the appointment to Thursday.'),
  (id: 'S05', text: 'Idea: a note about how the borrow checker error messages improved.'),
  (id: 'S06', text: 'Dinner at the Italian place on Friday at 8, table for six.'),
  (id: 'S07', text: 'The library book about Hannibal is due on the 14th.'),
  (id: 'S08', text: 'Rent is due on the first; transfer 640 euros from the savings account.'),
  (id: 'S09', text: 'Remember to buy blackout curtains for the spare room.'),
  (id: 'S10', text: 'Ask Priya whether the Kyoto guesthouse has a washing machine.'),
  (id: 'S11', text: 'New bike lights arrive Wednesday; they charge over USB-C.'),
  (id: 'S12', text: 'Watch the documentary about Jupiter\'s moons this weekend.'),
  (id: 'S13', text: 'Birthday gift for Anil: a chess clock and a book of endgames.'),
  (id: 'S14', text: 'Python meetup on Thursday evening, talk about type hints.'),
  (id: 'S15', text: 'Flour is running low, order a 5 kilo bag of strong white flour.'),
  (id: 'S16', text: 'Router firmware update announced for next month, read the notes.'),
];

/// Questions aimed at a short note: each shares its topic with a long note.
const shortQuestions = <CorpusQuestion>[
  (text: 'Which grinder did I buy for coffee?', noteId: 'S01', where: 'short'),
  (text: 'How far is my run tomorrow?', noteId: 'S02', where: 'short'),
  (text: 'What soup did I plan with roasted garlic?', noteId: 'S03', where: 'short'),
  (text: 'Which day is the dentist now?', noteId: 'S04', where: 'short'),
  (text: 'What did I want to write about compiler messages for references?', noteId: 'S05', where: 'short'),
  (text: 'When is the Italian restaurant booked?', noteId: 'S06', where: 'short'),
  (text: 'When must I return the book on the Carthaginian general?', noteId: 'S07', where: 'short'),
  (text: 'How much do I pay my landlord?', noteId: 'S08', where: 'short'),
  (text: 'What should I buy for the guest bedroom windows?', noteId: 'S09', where: 'short'),
  (text: 'What should I ask Priya about the accommodation in Japan?', noteId: 'S10', where: 'short'),
  (text: 'How do the new cycling lights charge?', noteId: 'S11', where: 'short'),
  (text: 'Which documentary am I planning to watch?', noteId: 'S12', where: 'short'),
  (text: 'What am I giving Anil for his birthday?', noteId: 'S13', where: 'short'),
  (text: 'What is the topic of the Thursday programming talk?', noteId: 'S14', where: 'short'),
  (text: 'What baking ingredient do I need to order?', noteId: 'S15', where: 'short'),
  (text: 'What is announced for next month on my network gear?', noteId: 'S16', where: 'short'),
];

/// Two questions about the start and two about the end of each long note.
const longQuestions = <CorpusQuestion>[
  (text: 'What yield and time do I target for a double espresso?', noteId: 'L01-espresso', where: 'start'),
  (text: 'What should I do if the shot is sour and runs in 18 seconds?', noteId: 'L01-espresso', where: 'start'),
  (text: 'How often do I descale the machine and with what?', noteId: 'L01-espresso', where: 'end'),
  (text: 'What do I do with the shower screen overnight?', noteId: 'L01-espresso', where: 'end'),
  (text: 'What happens to a String when I assign it to another variable?', noteId: 'L02-rust', where: 'start'),
  (text: 'How many mutable references may exist at once?', noteId: 'L02-rust', where: 'start'),
  (text: 'Why must benchmarks use the release profile?', noteId: 'L02-rust', where: 'end'),
  (text: 'Which smart pointers share ownership across threads?', noteId: 'L02-rust', where: 'end'),
  (text: 'What is my peak weekly distance in the training plan?', noteId: 'L03-marathon', where: 'start'),
  (text: 'What intervals do I run on Tuesday?', noteId: 'L03-marathon', where: 'start'),
  (text: 'What finishing time and split do I aim for on race day?', noteId: 'L03-marathon', where: 'end'),
  (text: 'What do I put on spots that chafe before the race?', noteId: 'L03-marathon', where: 'end'),
  (text: 'How do I get from the airport to Kyoto station?', noteId: 'L04-kyoto', where: 'start'),
  (text: 'Which district is the guesthouse in?', noteId: 'L04-kyoto', where: 'start'),
  (text: 'When do the cherry blossoms usually peak?', noteId: 'L04-kyoto', where: 'end'),
  (text: 'Which temple tickets should I book for the nine o\'clock slot?', noteId: 'L04-kyoto', where: 'end'),
  (text: 'What are the quantities of flour, water, starter and salt in my loaf?', noteId: 'L05-sourdough', where: 'start'),
  (text: 'How many stretch and folds do I do during the bulk?', noteId: 'L05-sourdough', where: 'start'),
  (text: 'What does it mean when the starter smells like nail polish remover?', noteId: 'L05-sourdough', where: 'end'),
  (text: 'What do I keep as insurance in case the main starter dies?', noteId: 'L05-sourdough', where: 'end'),
  (text: 'How many months of expenses go in the emergency fund?', noteId: 'L06-index-funds', where: 'start'),
  (text: 'What expense ratio limit do I set for the index fund?', noteId: 'L06-index-funds', where: 'start'),
  (text: 'How much of my money may go into individual stocks?', noteId: 'L06-index-funds', where: 'end'),
  (text: 'What do I read once a year about the fund?', noteId: 'L06-index-funds', where: 'end'),
  (text: 'When should I start tomato seeds indoors?', noteId: 'L07-tomatoes', where: 'start'),
  (text: 'Why bury the seedling stem deeper when repotting?', noteId: 'L07-tomatoes', where: 'start'),
  (text: 'What causes the black patch on the bottom of the fruit?', noteId: 'L07-tomatoes', where: 'end'),
  (text: 'Why should ripe tomatoes never go in the fridge?', noteId: 'L07-tomatoes', where: 'end'),
  (text: 'Which moon has the most volcanoes in the solar system?', noteId: 'L08-moons', where: 'start'),
  (text: 'Who discovered the four large moons of Jupiter and when?', noteId: 'L08-moons', where: 'start'),
  (text: 'Why does Triton orbit backwards?', noteId: 'L08-moons', where: 'end'),
  (text: 'Where do the names of Uranus\'s moons come from?', noteId: 'L08-moons', where: 'end'),
  (text: 'In which year was the Republic founded and who was expelled?', noteId: 'L09-rome', where: 'start'),
  (text: 'What did the tribunes of the people have the power to do?', noteId: 'L09-rome', where: 'start'),
  (text: 'Who deposed the last western emperor and when?', noteId: 'L09-rome', where: 'end'),
  (text: 'When did Constantinople fall to the Ottomans?', noteId: 'L09-rome', where: 'end'),
  (text: 'Why do I keep a fixed wake-up time even at weekends?', noteId: 'L10-sleep', where: 'start'),
  (text: 'When is my last coffee of the day?', noteId: 'L10-sleep', where: 'start'),
  (text: 'How long do I sit in dim light if I cannot fall asleep?', noteId: 'L10-sleep', where: 'end'),
  (text: 'How much deep sleep does my watch show now?', noteId: 'L10-sleep', where: 'end'),
  (text: 'What tyre pressure do I run in 28 mm road tyres?', noteId: 'L11-bike', where: 'start'),
  (text: 'What do two small holes next to each other in the tube mean?', noteId: 'L11-bike', where: 'start'),
  (text: 'How often do I regrease the headset bearings?', noteId: 'L11-bike', where: 'end'),
  (text: 'What torque do carbon stem bolts need?', noteId: 'L11-bike', where: 'end'),
  (text: 'What does calling an async function actually return?', noteId: 'L12-asyncio', where: 'start'),
  (text: 'How do I start the event loop from a script?', noteId: 'L12-asyncio', where: 'start'),
  (text: 'What limits the number of simultaneous requests to an API?', noteId: 'L12-asyncio', where: 'end'),
  (text: 'Which environment variable logs coroutines that were never awaited?', noteId: 'L12-asyncio', where: 'end'),
  (text: 'How do I answer the Sicilian as White?', noteId: 'L13-chess', where: 'start'),
  (text: 'Which opening do I play as Black against 1.e4?', noteId: 'L13-chess', where: 'start'),
  (text: 'How much did my rating improve in eight months?', noteId: 'L13-chess', where: 'end'),
  (text: 'What do I do after every blunder in a game?', noteId: 'L13-chess', where: 'end'),
  (text: 'What is the gateway address on my home network?', noteId: 'L14-wifi', where: 'start'),
  (text: 'How is the ISP box configured to avoid double NAT?', noteId: 'L14-wifi', where: 'start'),
  (text: 'How often do I test a restore of the backups?', noteId: 'L14-wifi', where: 'end'),
  (text: 'What keeps the modem and NAS running in a short power cut?', noteId: 'L14-wifi', where: 'end'),
];

/// Notes over 5,000 characters: the fact being asked about sits at the very
/// end, past what the 1024 Gecko file reads (about 4,500 characters).
final veryLongNotes = <CorpusNote>[
  (
    id: 'V1-garden-log',
    text: '${_filler('garden log', _gardenSentences)}'
        ' In the final week of September I harvested exactly 41 kilograms of '
            'butternut squash from the back plot and stored them in the shed.',
  ),
  (
    id: 'V2-reading-notes',
    text: '${_filler('reading notes', _readingSentences)}'
        ' My conclusion on the last page was that the lighthouse keeper in the '
            'novel is named Ottoline Marsh and she never leaves the island.',
  ),
  (
    id: 'V3-project-diary',
    text: '${_filler('project diary', _projectSentences)}'
        ' The release was finally shipped on the eleventh of March after the '
            'payment provider approved our sandbox credentials.',
  ),
];

const veryLongQuestions = <CorpusQuestion>[
  (text: 'How many kilograms of squash did I harvest in September?', noteId: 'V1-garden-log', where: 'veryend'),
  (text: 'What is the lighthouse keeper called in the novel?', noteId: 'V2-reading-notes', where: 'veryend'),
  (text: 'On which date was the release finally shipped?', noteId: 'V3-project-diary', where: 'veryend'),
];

String _filler(String topic, List<String> sentences) {
  final b = StringBuffer();
  var i = 0;
  while (b.length < 5400) {
    b.write(sentences[i % sentences.length]);
    b.write(i % 4 == 3 ? '\n\n' : ' ');
    i++;
  }
  return b.toString();
}

const _gardenSentences = <String>[
  'The beds were turned over in early spring and mixed with compost from the bin.',
  'Rain came in short heavy bursts which left the paths muddy for most of May.',
  'The beans climbed the bamboo frame faster than I expected this year.',
  'Slugs took half of the lettuce seedlings, so I switched to copper tape.',
  'We ate the first courgettes in July and had more than we could give away.',
  'The apple tree dropped a lot of small fruit in June, which is normal thinning.',
  'I kept a record of every watering to see whether the soil dried too fast.',
  'Marigolds between the rows seemed to keep the aphids on the beans under control.',
];

const _readingSentences = <String>[
  'The first part of the book introduces the island and the small community there.',
  'The prose is slow and patient, and the weather seems like another character.',
  'I liked the chapter where the supply boat fails to arrive for three weeks.',
  'There are long descriptions of the sea that I read twice for their rhythm.',
  'The narrator slowly reveals that her family history is tied to the lamp room.',
  'A subplot about letters never answered carries the emotional weight of the middle.',
  'The pacing speeds up in the last third once the storm approaches the coast.',
  'Notes to self: reread the passage about the logbook and its missing pages.',
];

const _projectSentences = <String>[
  'We spent the first sprint agreeing on the checkout flow with the designer.',
  'The staging server kept running out of memory until we raised the limit.',
  'A bug in the date parser broke invoices for customers in two time zones.',
  'We rewrote the cart as a state machine and the edge cases became obvious.',
  'The security review asked for rate limits on the login endpoint, which we added.',
  'Daily standups shrank to ten minutes once the backlog was groomed.',
  'Load tests showed the database was fine but the image resizer was the bottleneck.',
  'The retrospective listed slow reviews as the top complaint and we fixed it.',
];
