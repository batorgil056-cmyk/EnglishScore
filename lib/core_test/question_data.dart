/// Original practice material, authored for this local demo (not EnglishScore).
enum CorePart {
  grammar('Grammar and Vocabulary', 42),
  reading('Reading', 90),
  listening('Listening', 105);

  const CorePart(this.title, this.questionSeconds);
  final String title;
  final int questionSeconds;
  int get number => index + 1;
}

enum QuestionKind { choice, ordering, listening }

enum CoreSkill { grammar, vocabulary, reading, listening }

// Explicit content classification; none of the 55 prompts/answers are changed.
const vocabularyQuestionIds = {
  'g01',
  'g03',
  'g07',
  'g11',
  'g15',
  'g20',
  'g26',
  'g28',
  'g29'
};

class CoreQuestion {
  const CoreQuestion(
      {required this.id,
      required this.part,
      required this.level,
      required this.heading,
      required this.prompt,
      this.choices = const [],
      this.correctChoice,
      this.passage,
      this.sentences = const [],
      this.script,
      this.kind = QuestionKind.choice});

  final String id;
  final CorePart part;
  final String level;
  final String heading;
  final String prompt;
  final List<String> choices;
  final int? correctChoice;
  final String? passage;

  /// Canonical order. The opening sentence stays locked; the rest are shuffled.
  final List<String> sentences;
  final String? script;
  final QuestionKind kind;

  CoreSkill get skill => switch (part) {
        CorePart.reading => CoreSkill.reading,
        CorePart.listening => CoreSkill.listening,
        CorePart.grammar => vocabularyQuestionIds.contains(id)
            ? CoreSkill.vocabulary
            : CoreSkill.grammar,
      };

  List<int> get initialOrder =>
      kind == QuestionKind.ordering ? [0, 2, 3, 1] : [];
}

const grammarQuestions = <CoreQuestion>[
  CoreQuestion(
      id: 'g01',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'Leaving the restaurant',
      prompt: 'We have finished our meal. Could we have the ____, please?',
      choices: ['menu', 'bill', 'recipe'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g02',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'A weekend plan',
      prompt: 'If it is sunny on Saturday, we ____ a picnic by the river.',
      choices: ['will have', 'had', 'having'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g03',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'At the library',
      prompt: 'I would like to ____ this novel for a week.',
      choices: ['lend', 'owe', 'borrow'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g04',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'Morning routine',
      prompt: 'My sister ____ the bus to school every morning.',
      choices: ['take', 'takes', 'taking'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g05',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'In the kitchen',
      prompt: 'There ____ two clean cups beside the sink.',
      choices: ['are', 'is', 'be'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g06',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'Making tea',
      prompt: 'Would you like ____ sugar in your tea?',
      choices: ['many', 'a', 'some'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g07',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'Finding the station',
      prompt:
          'Visitor: Is the station far from here?\nLocal: No, it is ____ the supermarket.',
      choices: ['between', 'opposite', 'through'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g08',
      part: CorePart.grammar,
      level: 'A1',
      heading: 'A new home',
      prompt: 'This is our new flat. ____ balcony faces the garden.',
      choices: ['Its', 'It', 'Their'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g09',
      part: CorePart.grammar,
      level: 'A2',
      heading: 'Yesterday evening',
      prompt: 'We ____ dinner when the lights went out.',
      choices: ['cook', 'have cooked', 'were cooking'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g10',
      part: CorePart.grammar,
      level: 'A2',
      heading: 'Buying a jacket',
      prompt: 'This jacket is ____ than the one I tried on earlier.',
      choices: ['cheap', 'cheaper', 'cheapest'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g11',
      part: CorePart.grammar,
      level: 'A2',
      heading: 'A helpful neighbour',
      prompt: 'Sam offered to ____ my plants while I was away.',
      choices: ['look after', 'look for', 'look up'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g12',
      part: CorePart.grammar,
      level: 'A2',
      heading: 'Travel experience',
      prompt: 'I ____ to Spain twice, but I have never visited Portugal.',
      choices: ['go', 'was going', 'have been'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g13',
      part: CorePart.grammar,
      level: 'A2',
      heading: 'At a café',
      prompt:
          'Server: Are you ready to order?\nCustomer: Could you give us ____ more minutes?',
      choices: ['a little', 'a few', 'much'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g14',
      part: CorePart.grammar,
      level: 'A2',
      heading: 'House rules',
      prompt: 'You ____ take off your shoes here; it is a house rule.',
      choices: ['must', 'might', 'would'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g15',
      part: CorePart.grammar,
      level: 'A2',
      heading: 'A busy afternoon',
      prompt: 'I cannot meet you at three because I have a dentist’s ____.',
      choices: ['advertisement', 'invitation', 'appointment'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g16',
      part: CorePart.grammar,
      level: 'B1',
      heading: 'A changing neighbourhood',
      prompt: 'A new cycle bridge ____ near our house last year.',
      choices: ['builds', 'was built', 'has building'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g17',
      part: CorePart.grammar,
      level: 'B1',
      heading: 'Choosing a course',
      prompt: 'The course ____ starts in September includes a work placement.',
      choices: ['which', 'who', 'where'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g18',
      part: CorePart.grammar,
      level: 'B1',
      heading: 'A missed train',
      prompt: 'By the time we reached the platform, our train ____.',
      choices: ['leaves', 'has left', 'had left'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g19',
      part: CorePart.grammar,
      level: 'B1',
      heading: 'Planning a trip',
      prompt:
          'If I ____ more free time, I would travel by train instead of flying.',
      choices: ['have', 'had', 'will have'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g20',
      part: CorePart.grammar,
      level: 'B1',
      heading: 'Working together',
      prompt: 'We need to ____ a decision before the manager returns.',
      choices: ['make', 'do', 'have'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g21',
      part: CorePart.grammar,
      level: 'B1',
      heading: 'A difficult choice',
      prompt: 'Despite ____ tired, Lina stayed to help clear the hall.',
      choices: ['be', 'she was', 'being'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g22',
      part: CorePart.grammar,
      level: 'B1',
      heading: 'Passing on a message',
      prompt: 'Maya said that she ____ the report the following morning.',
      choices: ['sends', 'would send', 'will sending'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g23',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'A different outcome',
      prompt: 'If we had checked the forecast, we ____ the walk.',
      choices: ['would have postponed', 'will postpone', 'would postpone'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g24',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'An unexpected delay',
      prompt: 'The delivery was delayed ____ a shortage of drivers.',
      choices: ['although', 'in spite', 'owing to'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g25',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'Changing habits',
      prompt: 'I am gradually getting used to ____ from home.',
      choices: ['work', 'working', 'worked'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g26',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'Reviewing a proposal',
      prompt:
          'The committee raised several ____ about the cost of the project.',
      choices: ['concerns', 'conclusions', 'permissions'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g27',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'A recommendation',
      prompt:
          'The guide recommended ____ tickets in advance to avoid the queue.',
      choices: ['to book', 'book', 'booking'],
      correctChoice: 2),
  CoreQuestion(
      id: 'g28',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'A convincing argument',
      prompt:
          'Her explanation was so ____ that even the sceptical members agreed.',
      choices: ['persuaded', 'persuasive', 'persuading'],
      correctChoice: 1),
  CoreQuestion(
      id: 'g29',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'Checking the evidence',
      prompt:
          'The figures need to be checked carefully before any conclusions are ____.',
      choices: ['drawn', 'pulled', 'painted'],
      correctChoice: 0),
  CoreQuestion(
      id: 'g30',
      part: CorePart.grammar,
      level: 'B2',
      heading: 'A revised schedule',
      prompt: 'No sooner had the meeting begun ____ the fire alarm rang.',
      choices: ['when', 'then', 'than'],
      correctChoice: 2),
];

const readingQuestions = <CoreQuestion>[
  CoreQuestion(
      id: 'r01',
      part: CorePart.reading,
      level: 'A2',
      heading: 'A rooftop garden',
      kind: QuestionKind.ordering,
      prompt: 'Drag the sentences into the correct order.',
      sentences: [
        'Last spring, residents of Cedar House decided to turn their empty roof into a garden.',
        'Before planting anything, they asked an engineer to check that the roof could support the extra weight.',
        'Once the engineer approved the plan, they filled lightweight boxes with soil and planted herbs.',
        'By the end of summer, the herbs were ready to share at a meal for everyone in the building.',
      ]),
  CoreQuestion(
      id: 'r02',
      part: CorePart.reading,
      level: 'A1',
      heading: 'A library notice',
      passage:
          'Oak Street Library will close at 4 p.m. on Friday for electrical repairs. Books can still be returned through the outside slot. The library will open as usual at 9 a.m. on Saturday.',
      prompt: 'What can visitors do after 4 p.m. on Friday?',
      choices: [
        'Use a library computer',
        'Return borrowed books',
        'Collect a new library card'
      ],
      correctChoice: 1),
  CoreQuestion(
      id: 'r03',
      part: CorePart.reading,
      level: 'A2',
      heading: 'A message from Nora',
      passage:
          'Hi Eli, our train now leaves at 10:20, not 10:50. Let’s meet outside the station café at 9:50 so we have time to buy lunch. I already have both tickets. Nora',
      prompt: 'Why does Nora want to meet at 9:50?',
      choices: [
        'To buy food before the train',
        'To change their tickets',
        'To have breakfast with the driver'
      ],
      correctChoice: 0),
  CoreQuestion(
      id: 'r04',
      part: CorePart.reading,
      level: 'A2',
      heading: 'A neighbourhood repair day',
      kind: QuestionKind.ordering,
      prompt: 'Drag the sentences into the correct order.',
      sentences: [
        'Ben brought his broken desk lamp to the neighbourhood repair day.',
        'At the welcome desk, a volunteer gave him a number and asked him to wait.',
        'When his number was called, an electrician examined the lamp and replaced a loose wire.',
        'Ben then tested the repaired lamp and thanked the electrician before taking it home.',
      ]),
  CoreQuestion(
      id: 'r05',
      part: CorePart.reading,
      level: 'A2',
      heading: 'An outdoor cinema',
      passage:
          'The outdoor cinema in Meadow Park is free, but seats cannot be reserved. Gates open at 7 p.m., and the film begins after sunset. Bring a blanket because the grass may be damp. If heavy rain is forecast, the screening will move to the community hall.',
      prompt: 'Where will the film be shown if heavy rain is expected?',
      choices: [
        'In a school gym',
        'At a different park',
        'Inside the community hall'
      ],
      correctChoice: 2),
  CoreQuestion(
      id: 'r06',
      part: CorePart.reading,
      level: 'B1',
      heading: 'Trying a different commute',
      passage:
          'For years, Ravi drove to work because he thought cycling would take too long. When roadworks doubled his journey time, he tried his bicycle. The ride took only twenty minutes, and he arrived feeling more alert. He now cycles most days, although he still takes the bus in icy weather.',
      prompt: 'What first persuaded Ravi to try cycling?',
      choices: [
        'A recommendation from his doctor',
        'Delays on his usual route',
        'A rise in bus fares'
      ],
      correctChoice: 1),
  CoreQuestion(
      id: 'r07',
      part: CorePart.reading,
      level: 'B1',
      heading: 'A missing sketchbook',
      kind: QuestionKind.ordering,
      prompt: 'Drag the sentences into the correct order.',
      sentences: [
        'While unpacking after an art class, Jo noticed that her sketchbook was missing.',
        'She phoned the studio and described the blue cover to the receptionist.',
        'The receptionist found a matching book under a chair and kept it behind the desk.',
        'The next morning, Jo returned to the studio to collect it.',
      ]),
  CoreQuestion(
      id: 'r08',
      part: CorePart.reading,
      level: 'B1',
      heading: 'A museum experiment',
      passage:
          'The River Museum recently replaced some printed labels with recordings made by local residents. Visitors can hear personal memories connected to the objects. Although a few people prefer reading at their own pace, most say the voices make the collection feel closer to everyday life. Printed information remains available beside every object.',
      prompt: 'What is the main purpose of the recordings?',
      choices: [
        'To connect objects with personal experiences',
        'To remove all written information',
        'To teach visitors how to record sound'
      ],
      correctChoice: 0),
  CoreQuestion(
      id: 'r09',
      part: CorePart.reading,
      level: 'B1',
      heading: 'Working at a bookshop',
      passage:
          'When Amira joined a small bookshop, she expected to spend most of her time recommending novels. Instead, she discovered that organising deliveries and updating the website were equally important. She still enjoys conversations with customers, but says the experience has taught her how much unseen work keeps a shop running.',
      prompt: 'What surprised Amira about her job?',
      choices: [
        'Customers rarely asked about books',
        'The website was no longer used',
        'There was substantial work beyond serving customers'
      ],
      correctChoice: 2),
  CoreQuestion(
      id: 'r10',
      part: CorePart.reading,
      level: 'B1',
      heading: 'A school podcast',
      kind: QuestionKind.ordering,
      prompt: 'Drag the sentences into the correct order.',
      sentences: [
        'A group of students decided to make a podcast about the history of their school.',
        'To gather stories for the first episode, they interviewed several former teachers.',
        'After editing those interviews, they recorded an introduction and added music they had composed themselves.',
        'They finally published the finished episode on the school website.',
      ]),
  CoreQuestion(
      id: 'r11',
      part: CorePart.reading,
      level: 'B2',
      heading: 'A flexible working trial',
      passage:
          'A design firm tested a four-day working week without reducing pay. Staff agreed to shorten routine meetings and reserve quiet hours for concentrated work. Output remained stable during the three-month trial, but managers warned that a busy season might produce different results. They extended the experiment rather than making the change permanent immediately.',
      prompt: 'Why did the managers extend the trial?',
      choices: [
        'To reduce employees’ salaries',
        'To see whether the results would hold in other conditions',
        'To replace quiet hours with more meetings'
      ],
      correctChoice: 1),
  CoreQuestion(
      id: 'r12',
      part: CorePart.reading,
      level: 'B2',
      heading: 'Borrowing instead of buying',
      passage:
          'A neighbourhood tool library lends equipment that many households use only occasionally. Its organisers say the main benefit is not simply saving money: members also exchange practical advice. However, every item must be checked on return, so the scheme relies on volunteers who know how to maintain the tools safely.',
      prompt: 'Which difficulty does the scheme need to manage?',
      choices: [
        'Finding people who can inspect and maintain equipment',
        'Persuading members to buy a full set of tools',
        'Stopping members from sharing advice'
      ],
      correctChoice: 0),
  CoreQuestion(
      id: 'r13',
      part: CorePart.reading,
      level: 'B2',
      heading: 'Restoring a riverside path',
      kind: QuestionKind.ordering,
      prompt: 'Drag the sentences into the correct order.',
      sentences: [
        'After winter storms damaged the riverside path, the council asked residents how it should be restored.',
        'The responses favoured a permeable surface rather than replacing the old concrete.',
        'Using that feedback, engineers designed a surface that would allow rainwater to drain through it.',
        'Once the new design was approved, construction began on the first section of the path.',
      ]),
  CoreQuestion(
      id: 'r14',
      part: CorePart.reading,
      level: 'B2',
      heading: 'A quiet shopping hour',
      passage:
          'A supermarket introduced an hour with dimmer lights and no background music for customers who find busy shops overwhelming. The trial attracted fewer people than an ordinary hour, but those who attended stayed longer and reported feeling more comfortable. The manager argues that success should be measured by accessibility as well as sales.',
      prompt: 'What is the manager’s view of the trial?',
      choices: [
        'It should stop because attendance was lower',
        'It succeeded only if it increased sales',
        'Its value includes making shopping easier for some customers'
      ],
      correctChoice: 2),
  CoreQuestion(
      id: 'r15',
      part: CorePart.reading,
      level: 'B2',
      heading: 'A community weather station',
      passage:
          'Volunteers installed weather sensors across a town to compare temperatures in different streets. Early readings suggested that shaded areas were cooler, but one sensor consistently reported unusually low values. Rather than dismissing the whole project, the volunteers checked its position and discovered it was too close to a ventilation outlet. They moved it and continued collecting data.',
      prompt: 'What does the response to the unusual readings show?',
      choices: [
        'The volunteers expected identical temperatures everywhere',
        'They investigated a possible measurement problem',
        'They abandoned their original research question'
      ],
      correctChoice: 1),
];

const listeningQuestions = <CoreQuestion>[
  CoreQuestion(
      id: 'l01',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'A1',
      heading: 'Two friends are arranging lunch.',
      script:
          'Maya says: Shall we meet at the café at twelve? Leo replies: I have a class until twelve thirty. Could we meet at one instead? Maya says: Yes, one o’clock is fine. I will book a table.',
      prompt: 'What time will they meet?',
      choices: ['Twelve o’clock', 'One o’clock', 'Twelve thirty'],
      correctChoice: 1),
  CoreQuestion(
      id: 'l02',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'A1',
      heading: 'You hear an announcement at a station.',
      script:
          'Attention please. The ten fifteen train to Lakeside will leave from platform four today, not platform two. Please check that you have all your belongings before boarding.',
      prompt: 'Which platform should passengers use?',
      choices: ['Platform four', 'Platform two', 'Platform ten'],
      correctChoice: 0),
  CoreQuestion(
      id: 'l03',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'A2',
      heading: 'A customer is speaking to a shop assistant.',
      script:
          'The customer says: I bought these shoes yesterday, but they are too small. The assistant replies: Would you like a refund? The customer says: No, I like the style. Do you have the same pair in a larger size?',
      prompt: 'What does the customer want?',
      choices: [
        'A different colour',
        'Her money back',
        'A larger pair of the same shoes'
      ],
      correctChoice: 2),
  CoreQuestion(
      id: 'l04',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'A2',
      heading: 'You hear a voicemail about a delivery.',
      script:
          'Hello, this is Mina from Green Basket. Your vegetable box will arrive on Thursday this week instead of Wednesday because our van needs a repair. The delivery time will still be between nine and eleven in the morning.',
      prompt: 'What has changed about the delivery?',
      choices: [
        'The time of day',
        'The day of the week',
        'The contents of the box'
      ],
      correctChoice: 1),
  CoreQuestion(
      id: 'l05',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'B1',
      heading: 'Two colleagues are discussing a meeting.',
      script:
          'Priya says: Can we use the large meeting room this afternoon? Tom replies: It is being painted. I have booked the small room upstairs, but we will need to borrow a screen. Priya says: I can bring the portable one from my office.',
      prompt: 'What will Priya bring?',
      choices: ['A portable screen', 'Some paint', 'Extra chairs'],
      correctChoice: 0),
  CoreQuestion(
      id: 'l06',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'B1',
      heading: 'A guide is talking to visitors.',
      script:
          'Welcome to the island nature reserve. The cliff path is closed while the steps are repaired, so our walk will follow the woodland trail. We will still reach the viewpoint, but please allow an extra twenty minutes for the return journey.',
      prompt: 'Why will the group use the woodland trail?',
      choices: [
        'It is the shortest route',
        'The viewpoint has moved',
        'The cliff path is under repair'
      ],
      correctChoice: 2),
  CoreQuestion(
      id: 'l07',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'B1',
      heading: 'A student is discussing a project with a tutor.',
      script:
          'The student says: I have collected twenty interviews, but I am not sure how to organise the findings. The tutor replies: Do not add more interviews yet. First, group the comments by theme. That will help you see which ideas appear most often.',
      prompt: 'What does the tutor recommend doing next?',
      choices: [
        'Collecting twenty more interviews',
        'Grouping the existing comments by theme',
        'Writing the final conclusion immediately'
      ],
      correctChoice: 1),
  CoreQuestion(
      id: 'l08',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'B2',
      heading: 'You hear a radio update about a town festival.',
      script:
          'Organisers say this year’s festival will go ahead despite a smaller budget. Rather than cutting the number of events, they have asked local venues to donate space. Ticket prices will remain unchanged, and any surplus will help fund next year’s programme.',
      prompt: 'How are the organisers responding to the smaller budget?',
      choices: [
        'Using venues that provide space for free',
        'Reducing the number of events',
        'Increasing ticket prices'
      ],
      correctChoice: 0),
  CoreQuestion(
      id: 'l09',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'B2',
      heading: 'Two neighbours are talking about a building proposal.',
      script:
          'Anna says: I expected the new community centre to make the street noisier. David replies: So did I, but the revised design puts the entrance on the main road and adds sound insulation. Anna says: That addresses my biggest concern. I would still like to see a clear parking plan.',
      prompt: 'How does Anna feel about the revised proposal?',
      choices: [
        'She is opposed to every part of it',
        'She no longer has any questions',
        'She is more positive but still has a concern'
      ],
      correctChoice: 2),
  CoreQuestion(
      id: 'l10',
      part: CorePart.listening,
      kind: QuestionKind.listening,
      level: 'B2',
      heading: 'A manager is explaining a pilot scheme.',
      script:
          'We are introducing reusable containers in two branches for six weeks. Customers will pay a small deposit, which they get back when they return a container. We are not expanding the scheme yet. We first need to know whether enough containers come back to make cleaning and transport worthwhile.',
      prompt: 'What will determine whether the scheme expands?',
      choices: [
        'The colour customers prefer',
        'Whether enough containers are returned',
        'Whether deposits can be increased each week'
      ],
      correctChoice: 1),
];

const coreQuestions = <CoreQuestion>[
  ...grammarQuestions,
  ...readingQuestions,
  ...listeningQuestions
];
