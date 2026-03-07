import '../localization/app_strings.dart';

const List<String> _popularMaterialKeys = <String>[
  'angora',
  'cotton',
  'linen',
  'wool',
  'silk',
  'leather',
  'eco_leather',
  'denim',
];

const List<String> _materialKeys = <String>[
  'angora',
  'cotton',
  'linen',
  'wool',
  'silk',
  'viscose',
  'denim',
  'leather',
  'eco_leather',
  'suede',
  'polyester',
  'polyamide',
  'acrylic',
  'cashmere',
  'satin',
  'chiffon',
  'organza',
  'velvet',
  'jersey',
  'knitwear',
  'fleece',
  'tweed',
  'lace',
  'gabardine',
  'crepe',
  'rayon',
  'nylon',
  'spandex',
  'bamboo',
  'modal',
];

const alphaSizeSuggestions = <String>[
  'XS',
  'S',
  'M',
  'L',
  'XL',
  'XXL',
  'XXXL',
  '4XL',
  '5XL',
];

const numericSizeSuggestions = <String>[
  '54',
  '55',
  '56',
  '57',
  '58',
  '59',
  '60',
  '61',
  '62',
  '63',
  '64',
  '65',
  '66',
  '67',
  '68',
  '69',
  '70',
];

const List<String> _specialSizeKeys = <String>[
  'standard',
  'oversize',
  'free_size',
];

const List<String> _popularColorKeys = <String>[
  'black',
  'white',
  'beige',
  'blue',
  'brown',
  'gray',
  'green',
  'red',
];

const List<String> _colorKeys = <String>[
  'black',
  'white',
  'beige',
  'blue',
  'navy',
  'sky_blue',
  'brown',
  'chocolate',
  'gray',
  'silver',
  'green',
  'olive',
  'mint',
  'red',
  'burgundy',
  'pink',
  'fuchsia',
  'purple',
  'lilac',
  'yellow',
  'mustard',
  'orange',
  'milk',
  'cream',
  'graphite',
  'khaki',
];

const Map<String, Map<String, String>> _materialDictionary =
    <String, Map<String, String>>{
      'angora': {'ru': 'Ангора', 'en': 'Angora', 'zh': '安哥拉'},
      'cotton': {'ru': 'Хлопок', 'en': 'Cotton', 'zh': '棉'},
      'linen': {'ru': 'Лён', 'en': 'Linen', 'zh': '亚麻'},
      'wool': {'ru': 'Шерсть', 'en': 'Wool', 'zh': '羊毛'},
      'silk': {'ru': 'Шёлк', 'en': 'Silk', 'zh': '丝绸'},
      'leather': {'ru': 'Кожа', 'en': 'Leather', 'zh': '皮革'},
      'eco_leather': {'ru': 'Эко кожа', 'en': 'Eco Leather', 'zh': '环保皮'},
      'denim': {'ru': 'Деним', 'en': 'Denim', 'zh': '牛仔布'},
      'viscose': {'ru': 'Вискоза', 'en': 'Viscose', 'zh': '粘胶'},
      'suede': {'ru': 'Замша', 'en': 'Suede', 'zh': '麂皮'},
      'polyester': {'ru': 'Полиэстер', 'en': 'Polyester', 'zh': '涤纶'},
      'polyamide': {'ru': 'Полиамид', 'en': 'Polyamide', 'zh': '锦纶'},
      'acrylic': {'ru': 'Акрил', 'en': 'Acrylic', 'zh': '腈纶'},
      'cashmere': {'ru': 'Кашемир', 'en': 'Cashmere', 'zh': '羊绒'},
      'satin': {'ru': 'Сатин', 'en': 'Satin', 'zh': '缎面'},
      'chiffon': {'ru': 'Шифон', 'en': 'Chiffon', 'zh': '雪纺'},
      'organza': {'ru': 'Органза', 'en': 'Organza', 'zh': '欧根纱'},
      'velvet': {'ru': 'Бархат', 'en': 'Velvet', 'zh': '天鹅绒'},
      'jersey': {'ru': 'Джерси', 'en': 'Jersey', 'zh': '针织平纹'},
      'knitwear': {'ru': 'Трикотаж', 'en': 'Knitwear', 'zh': '针织'},
      'fleece': {'ru': 'Флис', 'en': 'Fleece', 'zh': '抓绒'},
      'tweed': {'ru': 'Твид', 'en': 'Tweed', 'zh': '粗花呢'},
      'lace': {'ru': 'Кружево', 'en': 'Lace', 'zh': '蕾丝'},
      'gabardine': {'ru': 'Габардин', 'en': 'Gabardine', 'zh': '华达呢'},
      'crepe': {'ru': 'Креп', 'en': 'Crepe', 'zh': '绉布'},
      'rayon': {'ru': 'Район', 'en': 'Rayon', 'zh': '人造丝'},
      'nylon': {'ru': 'Нейлон', 'en': 'Nylon', 'zh': '尼龙'},
      'spandex': {'ru': 'Спандекс', 'en': 'Spandex', 'zh': '氨纶'},
      'bamboo': {'ru': 'Бамбук', 'en': 'Bamboo', 'zh': '竹纤维'},
      'modal': {'ru': 'Модал', 'en': 'Modal', 'zh': '莫代尔'},
    };

const Map<String, Map<String, String>> _specialSizeDictionary =
    <String, Map<String, String>>{
      'standard': {'ru': 'Стандарт', 'en': 'Standard', 'zh': '标准'},
      'oversize': {'ru': 'Оверсайз', 'en': 'Oversize', 'zh': '宽松版'},
      'free_size': {'ru': 'Свободный', 'en': 'Free Size', 'zh': '均码'},
    };

const Map<String, Map<String, String>> _colorDictionary =
    <String, Map<String, String>>{
      'black': {'ru': 'Черный', 'en': 'Black', 'zh': '黑色'},
      'white': {'ru': 'Белый', 'en': 'White', 'zh': '白色'},
      'beige': {'ru': 'Бежевый', 'en': 'Beige', 'zh': '米色'},
      'blue': {'ru': 'Синий', 'en': 'Blue', 'zh': '蓝色'},
      'brown': {'ru': 'Коричневый', 'en': 'Brown', 'zh': '棕色'},
      'gray': {'ru': 'Серый', 'en': 'Gray', 'zh': '灰色'},
      'green': {'ru': 'Зеленый', 'en': 'Green', 'zh': '绿色'},
      'red': {'ru': 'Красный', 'en': 'Red', 'zh': '红色'},
      'navy': {'ru': 'Темно-синий', 'en': 'Navy', 'zh': '藏青色'},
      'sky_blue': {'ru': 'Голубой', 'en': 'Sky Blue', 'zh': '天蓝色'},
      'chocolate': {'ru': 'Шоколадный', 'en': 'Chocolate', 'zh': '巧克力色'},
      'silver': {'ru': 'Серебристый', 'en': 'Silver', 'zh': '银色'},
      'olive': {'ru': 'Оливковый', 'en': 'Olive', 'zh': '橄榄色'},
      'mint': {'ru': 'Мятный', 'en': 'Mint', 'zh': '薄荷色'},
      'burgundy': {'ru': 'Бордовый', 'en': 'Burgundy', 'zh': '酒红色'},
      'pink': {'ru': 'Розовый', 'en': 'Pink', 'zh': '粉色'},
      'fuchsia': {'ru': 'Фуксия', 'en': 'Fuchsia', 'zh': '玫红色'},
      'purple': {'ru': 'Фиолетовый', 'en': 'Purple', 'zh': '紫色'},
      'lilac': {'ru': 'Сиреневый', 'en': 'Lilac', 'zh': '淡紫色'},
      'yellow': {'ru': 'Желтый', 'en': 'Yellow', 'zh': '黄色'},
      'mustard': {'ru': 'Горчичный', 'en': 'Mustard', 'zh': '芥末色'},
      'orange': {'ru': 'Оранжевый', 'en': 'Orange', 'zh': '橙色'},
      'milk': {'ru': 'Молочный', 'en': 'Milk', 'zh': '乳白色'},
      'cream': {'ru': 'Кремовый', 'en': 'Cream', 'zh': '奶油色'},
      'graphite': {'ru': 'Графитовый', 'en': 'Graphite', 'zh': '石墨色'},
      'khaki': {'ru': 'Хаки', 'en': 'Khaki', 'zh': '卡其色'},
    };

List<String> localizedPopularMaterialSuggestions(AppLanguage language) {
  return _localizedList(_popularMaterialKeys, _materialDictionary, language);
}

List<String> localizedMaterialSuggestions(AppLanguage language) {
  return _localizedList(_materialKeys, _materialDictionary, language);
}

List<String> localizedSpecialSizeSuggestions(AppLanguage language) {
  return _localizedList(_specialSizeKeys, _specialSizeDictionary, language);
}

List<String> localizedSizeSuggestions(AppLanguage language) {
  return <String>[
    ...alphaSizeSuggestions,
    ...numericSizeSuggestions,
    ...localizedSpecialSizeSuggestions(language),
  ];
}

List<String> localizedPopularColorSuggestions(AppLanguage language) {
  return _localizedList(_popularColorKeys, _colorDictionary, language);
}

List<String> localizedColorSuggestions(AppLanguage language) {
  return _localizedList(_colorKeys, _colorDictionary, language);
}

String localizeMaterialValue(AppLanguage language, String value) {
  return _localizeSingleValue(value, _materialDictionary, language);
}

String localizeColorValue(AppLanguage language, String value) {
  return _localizeSingleValue(value, _colorDictionary, language);
}

String localizeSizeValue(AppLanguage language, String value) {
  if (value.trim().isEmpty) {
    return value;
  }

  return value
      .split(',')
      .map(
        (token) => _localizeSingleValue(
          token.trim(),
          _specialSizeDictionary,
          language,
        ),
      )
      .join(', ');
}

List<String> _localizedList(
  List<String> keys,
  Map<String, Map<String, String>> dictionary,
  AppLanguage language,
) {
  return keys.map((key) => _localizedLabel(key, dictionary, language)).toList();
}

String _localizedLabel(
  String key,
  Map<String, Map<String, String>> dictionary,
  AppLanguage language,
) {
  final entry = dictionary[key];
  if (entry == null) {
    return key;
  }

  return entry[language.code] ?? entry['en'] ?? key;
}

String _localizeSingleValue(
  String value,
  Map<String, Map<String, String>> dictionary,
  AppLanguage language,
) {
  final key = _resolveCatalogKey(value, dictionary);
  if (key == null) {
    return value;
  }

  return _localizedLabel(key, dictionary, language);
}

String? _resolveCatalogKey(
  String value,
  Map<String, Map<String, String>> dictionary,
) {
  final normalizedValue = _normalizeCatalogValue(value);

  if (normalizedValue.isEmpty) {
    return null;
  }

  for (final entry in dictionary.entries) {
    if (_normalizeCatalogValue(entry.key) == normalizedValue) {
      return entry.key;
    }

    for (final label in entry.value.values) {
      if (_normalizeCatalogValue(label) == normalizedValue) {
        return entry.key;
      }
    }
  }

  return null;
}

String _normalizeCatalogValue(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
