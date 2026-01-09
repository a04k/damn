
final List<Map<String, dynamic>> Departments = [
    {
      'title': 'Mathematics',
      'subtitle': 'رياضيات – علوم الحاسب – إحصاء رياضي',
      'ARinformation':'بعد الفصل الدراسي الاول المستوى الاول يختار الطالب بالتنسيق :\n رياضيات\nعلوم الحاسب\n إحصاء رياضي\n\nبعد الفصل الدراسي الثاني المستوى الاول\nطالب برنامج الرياضيات مستمرون حتى التخرج بهذا البرنامج.\n\n طالب برنامج علوم الحاسب يختار بالتنسيق بين \n برنامج علوم الحاسب   =>  منفرد\nبرنامج بحتة – حاسب  => مزدوج\nويستمر الطالب بالبرنامج حتى تخرجه .\n\n طالب برنامج إحصاء رياضي يختار بالتنسيق بين \n برنامج إحصاء   =>  منفرد\n برنامج بحتة- إحصاء رياضي=> مزدوج\n برنامج إحصاء رياضي- حاسب=> مزدوج\nويستمر الطالب بالبرنامج حتى تخرجه.',
      'ENinformation':'After the first semester of the first level, the student chooses in coordination:\n Mathematics\n Computer Science\n Mathematical Statistics\n\nAfter the second semester of the first level\nStudents of the Mathematics program continue until graduation with this program.\n\n Students of the Computer Science program choose in coordination between\n Computer Science Program => Single\n Pure - Computer => Double\nAnd the student continues with the program until his graduation.\n\n Students of the Mathematical Statistics program choose in coordination between\n Statistics Program => Single\n Pure - Mathematical Statistics => Double\n Mathematical Statistics - Computer => Double\nAnd the student continues with the program until his graduation.',
      'isMath':true,
      'isScience':true,
      'finalProgramsAR':[
        'رياضيات',
        'احصاء-حاسب',
        'بحتة-احصاء',
        'بحتة-حاسب',
        'علوم الحاسب',
        'إحصاء رياضي',
      ],
      'finalProgramsEN':[
        'Mathematics',
        'Statistics-Computer',
        'Pure-Statistics',
        'Pure-Computer',
        'Computer Science',
        'Mathematical Statistics',
      ],
    },
    {
      'title': 'Physics',
      'subtitle': 'فيزياء منفردة ومزدوجة',
      'ARinformation':'بعد الفصل الدراسي الاول المستوى الاول يختار بين :\n فيزياء => منفرد\n فيزياء- حاسب => مزدوج\nفيزياء- كيمياء=> مزدوج\nويستمر الطالب بالبرنامج حتى تخرجه.',
      'ENinformation':'After the first semester of the first level, he chooses between:\n Physics => Single\n Physics - Computer => Double\n Physics - Chemistry => Double\nAnd the student continues with the program until his graduation.' ,
      'isMath':true,
      'isScience':true,
      'finalProgramsAR':[
         'فيزياء منفردة',
         'فيزياء- حاسب',
         'فيزياء- كيمياء',
        ],
        'finalProgramsEN':[
        'Single Physics',
        'Physics- Computer',
        'Physics- Chemistry',
        ],
    },
    {
      'title': 'Biophysics',
      'subtitle': 'برنامج الفيزياء الحيوية',
      'ARinformation':'برنامج وفقا يلتحق الطالب بال للشروط الموجودة بإستمارة رغبات اإللتحاق بالمستو األول ويستمربالدراسة بالبرنامج حتى تخرجه.',
      'ENinformation':'According to the conditions in the application form for admission to the first level, the student joins and continues studying in the program until his graduation.',
      'isMath':true,
      'isScience':true,
      'finalProgramsAR':[
        'فيزياء حيوية',
      ],
      'finalProgramsEN':[
        'Biophysics',
      ],
    },
    {
      'title': 'Chemistry',
      'subtitle': 'كيمياء أساسية وتطبيقية',
      'ARinformation': 'بعد نهاية المستوى الثاني يختار بين :\n  يستمر الطالب في برنامج الكيمياء " الاساسي" حتى تخرجه \n يختار برنامج الكيمياء التطبيقية و يستمر به حتى التخرج',
      'ENinformation':'After the end of the second level, he chooses between:\n The student continues in the Chemistry "Basic" program until his graduation\n He chooses the Applied Chemistry program and continues with it until graduation',   
      'isMath':true,
      'isScience':true,
      'finalProgramsAR':[
       'كيمياء أساسية',
        'كيمياء تطبيقية',
        ],
        'finalProgramsEN':[
         'Basic Chemistry',
          'Applied Chemistry',
        ],  
     },
    {
      'title': 'Geology',
      'subtitle': 'جيولوجيا وبرامج مزدوجة',
      'ARinformation':'بعد الفصل الدراسي الاول المستوى الاول يختار بين :\nبرنامج الجيولوجيا => منفرد \nبرنامج جيولوجيا - كيمياء => مزدوج \nبرنامج جيولوجيا - جيوفيزياء => مزدوج \nو يستمر بالبرنامج حتى التخرج',
      'ENinformation':'After the first semester of the first level, he chooses between:\n Geology Program => Single\n Geology - Chemistry Program => Double\n Geology - Geophysics Program => Double\nAnd continues with the program until graduation.',
      'isMath':true,
      'isScience':true,
      'finalProgramsAR':[
       'جيولوجيا منفردة'
       'جيولوجيا- كيمياء'
        'جيولوجيا- جيوفيزياء'
       
      ],
      'finalProgramsEN':[ 
        'Single Geology', 
        'Geology-Chemistry', 
        'Geology-Geophysics'
        ],
    },
    {
      'title': 'Geophysics',
      'subtitle': 'برنامج الجيوفيزياء',
      'ARinformation':'يلتحق الطالب بالبرنامج عند دخول الكلية بالمستوى الاول و يستمر حتى التخرج ',
      'ENinformation':'The student joins the program upon entering the college at the first level and continues until graduation.',
      'isMath':true,
      'isScience':true,
      'finalProgramsAR':[
       'جيوفيزياء'
      ],
      'finalProgramsEN':[
       'Geophysics'
      ],
    },
    {
      'title': 'Biology',
      'subtitle': 'برامج منفردة ومزدوجة',
      'ARinformation':'بعد الفصل الدراسي الثاني المستوى الاول يختار وفقا للشروط :\n\nبرامج منفردة:\n النبات \n علم الحيوان \n علم الحشرات\n الكيمياء الحيوية \n الميكروبيولوجي\n علم الحشرات الطبية\n\n برامج مزدوجة:\n النبات- الكيمياء \n علم الحيوان- الكيمياء \n علم الحشرات- الكيمياء\n الكيمياء الحيوية- الكيمياء \n الميكروبيولوجي- الكيمياء\n\n يستمر الطالب بالبرنامج حتى تخرجه.',
      'ENinformation':'After the second semester of the first level, he chooses according to the conditions:\n\nSingle Programs:\n Plant\n Zoology\n Entomology\n Biochemistry\n Microbiology\n Medical Entomology\n\n Double Programs:\n Plant-Chemistry\n Zoology-Chemistry\n Entomology-Chemistry\n Biochemistry-Chemistry\n Microbiology-Chemistry\n\n The student continues with the program until his graduation.',
      'isMath':false,
      'isScience':true,
      'finalProgramsAR':[
       'نبات',
        'الميكروبيولوجي -الكيمياء',
         'الكيمياء الحيوية-الكيمياء',
         'علم الحشرات-كيمياء',
         'علم الحيوان-كيمياء',
         'النبات-كيمياء',
         'علم الحشرات الطبية  ',
         'علم الحيوان',
         'علم الحشرات',
         'كيمياء حيوية',
         'ميكروبيولوجي', 
         'علم الحشرات', 
         'كيمياء حيوية', 
         'ميكروبيولوجي',
        ],
      'finalProgramsEN':[
        'Plant', 
        'Microbiology-Chemistry', 
        'Biochemistry-Chemistry', 
        'Entomology-Chemistry', 
        'Zoology-Chemistry', 
        'Plant-Chemistry', 
        'Medical Entomology', 
        'Zoology', 
        'Entomology', 
        'Biochemistry', 
        'Microbiology', 
        'Plant', 
        'Biochemistry', 
        'Microbiology',
        ],
    },
  ];
  
  
