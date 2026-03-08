import 'package:flutter/material.dart';

enum AppLanguage {
  ru('ru', Locale('ru')),
  en('en', Locale('en')),
  zh('zh', Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

  const AppLanguage(this.code, this.locale);

  final String code;
  final Locale locale;

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'ru':
        return AppLanguage.ru;
      case 'zh':
        return AppLanguage.zh;
      case 'en':
      default:
        return AppLanguage.en;
    }
  }

  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }

  String get nativeLabel {
    switch (this) {
      case AppLanguage.ru:
        return 'Русский';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.zh:
        return '中文';
    }
  }
}

class AppStrings {
  AppStrings(this.language);

  final AppLanguage language;

  static AppStrings of(BuildContext context) {
    return AppStrings(AppLanguage.fromLocale(Localizations.localeOf(context)));
  }

  String t(String key) {
    final value = _localizedValues[key];
    if (value == null) {
      return key;
    }

    return value[language.code] ?? value['en'] ?? key;
  }

  String formatShopCount(int count) {
    switch (language) {
      case AppLanguage.ru:
        return '$count магазинов';
      case AppLanguage.en:
        return '$count shops';
      case AppLanguage.zh:
        return '$count 家店铺';
    }
  }

  String formatProductCount(int count) {
    switch (language) {
      case AppLanguage.ru:
        return '$count товаров';
      case AppLanguage.en:
        return '$count products';
      case AppLanguage.zh:
        return '$count 件商品';
    }
  }

  String formatFavoriteCount(int count) {
    switch (language) {
      case AppLanguage.ru:
        return '$count избранных';
      case AppLanguage.en:
        return '$count favorites';
      case AppLanguage.zh:
        return '$count 个收藏';
    }
  }

  String formatShopItemCount(int count) {
    switch (language) {
      case AppLanguage.ru:
        return '$count товаров';
      case AppLanguage.en:
        return '$count items';
      case AppLanguage.zh:
        return '$count 件商品';
    }
  }

  String localizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'new':
        return t('statusNew');
      default:
        return status;
    }
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'createTab': {'ru': 'Создать', 'en': 'Create', 'zh': '创建'},
    'shopsTab': {'ru': 'Магазины', 'en': 'Shops', 'zh': '店铺'},
    'favoritesTab': {'ru': 'Избранные', 'en': 'Favorites', 'zh': '收藏'},
    'save': {'ru': 'Сохранить', 'en': 'Save', 'zh': '保存'},
    'saving': {'ru': 'Сохраняем...', 'en': 'Saving...', 'zh': '保存中...'},
    'cancel': {'ru': 'Отмена', 'en': 'Cancel', 'zh': '取消'},
    'delete': {'ru': 'Удалить', 'en': 'Delete', 'zh': '删除'},
    'edit': {'ru': 'Редактировать', 'en': 'Edit', 'zh': '编辑'},
    'share': {'ru': 'Поделиться', 'en': 'Share', 'zh': '分享'},
    'remove': {'ru': 'Убрать', 'en': 'Remove', 'zh': '移除'},
    'gallery': {'ru': 'Галерея', 'en': 'Gallery', 'zh': '相册'},
    'camera': {'ru': 'Камера', 'en': 'Camera', 'zh': '相机'},
    'close': {'ru': 'Закрыть', 'en': 'Close', 'zh': '关闭'},
    'expand': {'ru': 'Развернуть', 'en': 'Expand', 'zh': '展开'},
    'collapse': {'ru': 'Свернуть', 'en': 'Collapse', 'zh': '收起'},
    'preview': {'ru': 'Предпросмотр', 'en': 'Preview', 'zh': '预览'},
    'language': {'ru': 'Язык', 'en': 'Language', 'zh': '语言'},
    'otherOptions': {
      'ru': 'Другие варианты',
      'en': 'Other options',
      'zh': '其他选项',
    },
    'suggestions': {'ru': 'Подсказки', 'en': 'Suggestions', 'zh': '建议'},
    'yes': {'ru': 'Да', 'en': 'Yes', 'zh': '是'},
    'no': {'ru': 'Нет', 'en': 'No', 'zh': '否'},
    'notSpecified': {'ru': 'Не указано', 'en': 'Not specified', 'zh': '未填写'},
    'newShop': {'ru': 'Новый магазин', 'en': 'New shop', 'zh': '新店铺'},
    'statusNew': {'ru': 'Новый', 'en': 'New', 'zh': '新的'},
    'settingsTitle': {'ru': 'Настройки', 'en': 'Settings', 'zh': '设置'},
    'settingsDescription': {
      'ru': 'Здесь можно изменить имя в шапке и выбрать язык приложения.',
      'en': 'Here you can change the header name and the app language.',
      'zh': '这里可以修改顶部名称并选择应用语言。',
    },
    'headerName': {'ru': 'Имя в шапке', 'en': 'Header name', 'zh': '顶部名称'},
    'yourName': {'ru': 'Ваше имя', 'en': 'Your name', 'zh': '你的名字'},
    'nameHint': {
      'ru': 'Например: Isobek',
      'en': 'Example: Isobek',
      'zh': '例如：Isobek',
    },
    'saveNameFailed': {
      'ru': 'Не удалось сохранить имя на сервере.',
      'en': 'Failed to save the name on the server.',
      'zh': '无法在服务器上保存名称。',
    },
    'createShopTitle': {
      'ru': 'Создать магазин',
      'en': 'Create shop',
      'zh': '创建店铺',
    },
    'createShopDescription': {
      'ru': 'Добавь фото и создай магазин. Остальное можно позже.',
      'en':
          'Add a photo and create the shop. Everything else can be filled later.',
      'zh': '先添加照片并创建店铺，其它内容之后再填。',
    },
    'shopPhoto': {'ru': 'Фото магазина', 'en': 'Shop photo', 'zh': '店铺照片'},
    'storefrontPhotos': {
      'ru': 'Фото витрины',
      'en': 'Storefront photos',
      'zh': '门头照片',
    },
    'storefrontHelper': {
      'ru': 'Сфотографируйте вход, вывеску или витрину магазина.',
      'en': 'Take photos of the entrance, signboard, or storefront.',
      'zh': '拍摄店铺入口、招牌或橱窗。',
    },
    'shopNameLabel': {
      'ru': 'Название магазина',
      'en': 'Shop name',
      'zh': '店铺名称',
    },
    'shopNameOptionalHint': {
      'ru': 'Можно оставить пустым',
      'en': 'Can be left empty',
      'zh': '可留空',
    },
    'shopLocationLabel': {
      'ru': 'Локация магазина',
      'en': 'Shop location',
      'zh': '店铺位置',
    },
    'shopLocationHint': {
      'ru': 'Ввести вручную или определить',
      'en': 'Enter manually or detect',
      'zh': '手动输入或自动定位',
    },
    'detectLocation': {
      'ru': 'Определить локацию',
      'en': 'Detect location',
      'zh': '定位当前位置',
    },
    'shopMapTitle': {'ru': 'Карта магазина', 'en': 'Shop map', 'zh': '店铺地图'},
    'mapPickPointTitle': {
      'ru': 'Поставь точку на карту',
      'en': 'Put a pin on the map',
      'zh': '在地图上放置标记',
    },
    'mapPickPointDescription': {
      'ru': 'Так потом можно будет открыть маршрут до магазина.',
      'en': 'This way you can open navigation to the shop later.',
      'zh': '这样以后可以直接导航到店铺。',
    },
    'changePoint': {'ru': 'Изменить точку', 'en': 'Change point', 'zh': '修改位置'},
    'pickOnMap': {
      'ru': 'Выбрать на карте',
      'en': 'Pick on map',
      'zh': '在地图上选择',
    },
    'myPoint': {'ru': 'Моя точка', 'en': 'My point', 'zh': '我的位置'},
    'extraDescriptionLabel': {
      'ru': 'Доп. описание',
      'en': 'Extra description',
      'zh': '补充说明',
    },
    'extraDescriptionHint': {
      'ru': 'Например: женская одежда, вечерние модели, доставка',
      'en': 'Example: women clothing, evening models, delivery',
      'zh': '例如：女装、晚礼服、可配送',
    },
    'businessCardTitle': {
      'ru': 'Визитка магазина',
      'en': 'Business card',
      'zh': '店铺名片',
    },
    'saveShop': {'ru': 'Создать магазин', 'en': 'Create shop', 'zh': '创建店铺'},
    'savingShop': {
      'ru': 'Сохраняем магазин...',
      'en': 'Saving shop...',
      'zh': '正在保存店铺...',
    },
    'heroShopBadge': {'ru': 'МАГАЗИН', 'en': 'SHOP', 'zh': '店铺'},
    'heroNewShopDescription': {
      'ru': 'Фото обязательно. Остальное можно заполнить позже.',
      'en': 'A photo is required. Everything else can be filled later.',
      'zh': '照片必填，其它内容稍后可补充。',
    },
    'photoReady': {'ru': 'Фото готово', 'en': 'Photo ready', 'zh': '照片已就绪'},
    'totalShops': {'ru': 'Всего магазинов', 'en': 'Total shops', 'zh': '店铺总数'},
    'totalPiecesLabel': {'ru': 'Всего штук', 'en': 'Total qty', 'zh': '总件数'},
    'grossTotalWithRateLabel': {
      'ru': 'Сумма без 10%',
      'en': 'Subtotal before 10%',
      'zh': '未扣10%总额',
    },
    'netTotalWithRateLabel': {
      'ru': 'Итог с 10%',
      'en': 'Total after 10%',
      'zh': '扣10%后总额',
    },
    'chooseOrTakePhoto': {
      'ru': 'Можно выбрать из галереи или сфотографировать.',
      'en': 'You can pick from gallery or take a photo.',
      'zh': '可以从相册选择或直接拍照。',
    },
    'addShopPhotoFirst': {
      'ru': 'Добавьте фото магазина.',
      'en': 'Add a shop photo.',
      'zh': '请添加店铺照片。',
    },
    'shopCreated': {
      'ru': 'Магазин создан.',
      'en': 'Shop created.',
      'zh': '店铺已创建。',
    },
    'cannotSaveShop': {
      'ru': 'Не удалось сохранить магазин на сервере.',
      'en': 'Failed to save the shop on the server.',
      'zh': '无法在服务器上保存店铺。',
    },
    'cannotLoadShopPhoto': {
      'ru': 'Не удалось загрузить фото магазина.',
      'en': 'Failed to load the shop photo.',
      'zh': '无法加载店铺照片。',
    },
    'cannotLoadBusinessCard': {
      'ru': 'Не удалось загрузить визитку.',
      'en': 'Failed to load the business card.',
      'zh': '无法加载名片。',
    },
    'cannotLoadStorefront': {
      'ru': 'Не удалось загрузить фото витрины.',
      'en': 'Failed to load storefront photos.',
      'zh': '无法加载门头照片。',
    },
    'cannotOpenStorefrontCamera': {
      'ru': 'Не удалось открыть камеру для витрины.',
      'en': 'Failed to open the camera for storefront photos.',
      'zh': '无法打开相机拍摄门头。',
    },
    'turnOnLocation': {
      'ru': 'Включите геолокацию на устройстве.',
      'en': 'Turn on location services on the device.',
      'zh': '请开启设备定位服务。',
    },
    'allowLocationAccess': {
      'ru': 'Разрешите доступ к геолокации.',
      'en': 'Allow location access.',
      'zh': '请允许定位权限。',
    },
    'cannotGetQuickLocation': {
      'ru': 'Не удалось быстро получить геолокацию.',
      'en': 'Failed to get the location quickly.',
      'zh': '无法快速获取定位。',
    },
    'cannotDetermineLocation': {
      'ru': 'Не удалось определить локацию.',
      'en': 'Failed to determine the location.',
      'zh': '无法确定位置。',
    },
    'shopsHeroBadge': {'ru': 'МАГАЗИНЫ', 'en': 'SHOPS', 'zh': '店铺'},
    'shopsHeroTitle': {'ru': 'Магазины', 'en': 'Shops', 'zh': '店铺'},
    'shopsHeroDescription': {
      'ru':
          'Здесь собраны все магазины. Открой нужный магазин и уже внутри создавай товары.',
      'en':
          'All shops are listed here. Open a shop and create products inside it.',
      'zh': '这里是所有店铺。打开店铺后可在里面创建商品。',
    },
    'noShopsTitle': {
      'ru': 'Пока нет магазинов',
      'en': 'No shops yet',
      'zh': '还没有店铺',
    },
    'noShopsDescription': {
      'ru': 'Создай магазин в первой вкладке, и он сразу появится здесь.',
      'en': 'Create a shop on the first tab and it will appear here.',
      'zh': '在第一个页面创建店铺后，它会立即显示在这里。',
    },
    'shopUpdated': {
      'ru': 'Магазин обновлён.',
      'en': 'Shop updated.',
      'zh': '店铺已更新。',
    },
    'cannotUpdateShop': {
      'ru': 'Не удалось обновить магазин.',
      'en': 'Failed to update the shop.',
      'zh': '无法更新店铺。',
    },
    'deleteShopTitle': {
      'ru': 'Удалить магазин?',
      'en': 'Delete shop?',
      'zh': '删除店铺？',
    },
    'deleteShopMessage': {
      'ru':
          'Магазин, товары и фото будут удалены без возможности восстановления.',
      'en': 'The shop, products, and photos will be deleted permanently.',
      'zh': '店铺、商品和照片将被永久删除。',
    },
    'shopDeleted': {
      'ru': 'Магазин удалён.',
      'en': 'Shop deleted.',
      'zh': '店铺已删除。',
    },
    'shopPinned': {
      'ru': 'Магазин закреплён вверху.',
      'en': 'Shop pinned to the top.',
      'zh': '店铺已固定在顶部。',
    },
    'shopUnpinned': {
      'ru': 'Магазин откреплён.',
      'en': 'Shop unpinned.',
      'zh': '店铺已取消固定。',
    },
    'cannotDeleteShop': {
      'ru': 'Не удалось удалить магазин.',
      'en': 'Failed to delete the shop.',
      'zh': '无法删除店铺。',
    },
    'pinShop': {'ru': 'Закрепить', 'en': 'Pin', 'zh': '固定'},
    'unpinShop': {'ru': 'Открепить', 'en': 'Unpin', 'zh': '取消固定'},
    'openShop': {'ru': 'Открыть магазин', 'en': 'Open shop', 'zh': '打开店铺'},
    'shopPhotoTitle': {'ru': 'Фото магазина', 'en': 'Shop photo', 'zh': '店铺照片'},
    'editShopTitle': {
      'ru': 'Редактировать магазин',
      'en': 'Edit shop',
      'zh': '编辑店铺',
    },
    'editShopDescription': {
      'ru': 'Измени название, локацию или описание.',
      'en': 'Change the name, location, or description.',
      'zh': '修改名称、位置或描述。',
    },
    'shopNameHint': {
      'ru': 'Например: Azaly',
      'en': 'Example: Azaly',
      'zh': '例如：Azaly',
    },
    'locationHintShort': {
      'ru': 'Адрес или район',
      'en': 'Address or district',
      'zh': '地址或区域',
    },
    'shortShopDescriptionHint': {
      'ru': 'Коротко про магазин',
      'en': 'Short description about the shop',
      'zh': '简单介绍店铺',
    },
    'pointOnMap': {'ru': 'Точка на карте', 'en': 'Map point', 'zh': '地图位置'},
    'pointNotSelected': {
      'ru': 'Точка пока не выбрана',
      'en': 'No point selected yet',
      'zh': '暂未选择位置',
    },
    'mapPointPageTitle': {
      'ru': 'Точка магазина',
      'en': 'Shop point',
      'zh': '店铺位置',
    },
    'cannotGetCurrentPoint': {
      'ru': 'Не удалось получить текущую точку.',
      'en': 'Failed to get the current point.',
      'zh': '无法获取当前位置。',
    },
    'cannotDetermineCurrentPoint': {
      'ru': 'Не удалось определить текущую точку.',
      'en': 'Failed to determine the current point.',
      'zh': '无法确定当前位置。',
    },
    'placePinOnMap': {
      'ru': 'Поставь метку на карту',
      'en': 'Place a pin on the map',
      'zh': '在地图上放置标记',
    },
    'tapWhereShopIs': {
      'ru': 'Нажми на карту там, где находится магазин.',
      'en': 'Tap the map where the shop is located.',
      'zh': '点击地图上店铺所在的位置。',
    },
    'purchaseTitle': {
      'ru': 'Закуп товара',
      'en': 'Purchase item',
      'zh': '进货商品',
    },
    'purchaseDescription': {
      'ru': 'Добавь фото, цену закупа, количество и нужные поля.',
      'en': 'Add photos, purchase price, quantity, and required fields.',
      'zh': '添加照片、进货价、数量和需要的字段。',
    },
    'purchaseCollapsedHint': {
      'ru': 'Форма скрыта. Нажми стрелку, чтобы снова открыть.',
      'en': 'The form is hidden. Tap the arrow to open it again.',
      'zh': '表单已隐藏，点击箭头再次打开。',
    },
    'cannotOpenGallery': {
      'ru': 'Не удалось открыть галерею.',
      'en': 'Failed to open the gallery.',
      'zh': '无法打开相册。',
    },
    'cannotOpenCamera': {
      'ru': 'Не удалось открыть камеру.',
      'en': 'Failed to open the camera.',
      'zh': '无法打开相机。',
    },
    'addProductPhotoFirst': {
      'ru': 'Сначала добавьте фото товара.',
      'en': 'Add product photos first.',
      'zh': '请先添加商品照片。',
    },
    'productCreated': {
      'ru': 'Товар создан внутри магазина.',
      'en': 'Product created inside the shop.',
      'zh': '商品已在店铺内创建。',
    },
    'cannotCreateProduct': {
      'ru': 'Не удалось создать товар.',
      'en': 'Failed to create the product.',
      'zh': '无法创建商品。',
    },
    'productUpdated': {
      'ru': 'Товар обновлён.',
      'en': 'Product updated.',
      'zh': '商品已更新。',
    },
    'cannotUpdateProduct': {
      'ru': 'Не удалось обновить товар.',
      'en': 'Failed to update the product.',
      'zh': '无法更新商品。',
    },
    'deleteProductTitle': {
      'ru': 'Удалить товар?',
      'en': 'Delete product?',
      'zh': '删除商品？',
    },
    'deleteProductMessage': {
      'ru': 'Товар будет удалён без возможности восстановления.',
      'en': 'The product will be deleted permanently.',
      'zh': '商品将被永久删除。',
    },
    'productDeleted': {
      'ru': 'Товар удалён.',
      'en': 'Product deleted.',
      'zh': '商品已删除。',
    },
    'cannotDeleteProduct': {
      'ru': 'Не удалось удалить товар.',
      'en': 'Failed to delete the product.',
      'zh': '无法删除商品。',
    },
    'movedToFavorites': {
      'ru': 'Товар перенесён в избранные.',
      'en': 'Product moved to favorites.',
      'zh': '商品已移到收藏。',
    },
    'favoriteMarked': {
      'ru': 'Товар отмечен как избранный.',
      'en': 'Product marked as favorite.',
      'zh': '商品已标记为收藏。',
    },
    'cannotUpdateFavorite': {
      'ru': 'Не удалось обновить избранное.',
      'en': 'Failed to update favorites.',
      'zh': '无法更新收藏。',
    },
    'shopNotFound': {
      'ru': 'Магазин не найден',
      'en': 'Shop not found',
      'zh': '未找到店铺',
    },
    'purchasePriceLabel': {
      'ru': 'Цена закупа',
      'en': 'Purchase price',
      'zh': '进货价',
    },
    'purchasePriceHint': {
      'ru': 'Например: 120 000',
      'en': 'Example: 120 000',
      'zh': '例如：120 000',
    },
    'quantityLabel': {'ru': 'Количество', 'en': 'Quantity', 'zh': '数量'},
    'colorLabel': {'ru': 'Цвет', 'en': 'Color', 'zh': '颜色'},
    'colorHint': {
      'ru': 'Например: Черный, Бежевый, Синий',
      'en': 'Example: Black, Beige, Blue',
      'zh': '例如：黑色、米色、蓝色',
    },
    'popularColors': {
      'ru': 'Популярные цвета',
      'en': 'Popular colors',
      'zh': '常用颜色',
    },
    'materialLabel': {'ru': 'Материал', 'en': 'Material', 'zh': '材质'},
    'materialHint': {
      'ru': 'Например: Ангора, Хлопок, Кожа',
      'en': 'Example: Angora, Cotton, Leather',
      'zh': '例如：安哥拉、棉、皮革',
    },
    'popular': {'ru': 'Популярные', 'en': 'Popular', 'zh': '常用'},
    'sizeLabel': {'ru': 'Размер', 'en': 'Size', 'zh': '尺码'},
    'sizeHint': {
      'ru': 'Например: XL, 58, Стандарт',
      'en': 'Example: XL, 58, Standard',
      'zh': '例如：XL、58、标准',
    },
    'alphaSizes': {
      'ru': 'Буквенные размеры',
      'en': 'Letter sizes',
      'zh': '字母尺码',
    },
    'numericSizes': {
      'ru': 'Числовые размеры',
      'en': 'Numeric sizes',
      'zh': '数字尺码',
    },
    'specialSizes': {'ru': 'Особые', 'en': 'Special', 'zh': '特殊尺码'},
    'savePurchase': {
      'ru': 'Сохранить закуп',
      'en': 'Save purchase',
      'zh': '保存进货',
    },
    'savingPurchase': {
      'ru': 'Сохраняем закуп...',
      'en': 'Saving purchase...',
      'zh': '正在保存进货...',
    },
    'shopPurchases': {
      'ru': 'Закупы магазина',
      'en': 'Shop purchases',
      'zh': '店铺进货',
    },
    'emptyProductImages': {
      'ru': 'Добавь фото товара, затем заполни сумму, материал и размер.',
      'en': 'Add product photos, then fill in the price, material, and size.',
      'zh': '先添加商品照片，再填写价格、材质和尺码。',
    },
    'emptyShopProducts': {
      'ru': 'В этом магазине пока нет товаров',
      'en': 'There are no products in this shop yet',
      'zh': '这个店铺里还没有商品',
    },
    'purchaseTotalTitle': {
      'ru': 'Итог закупа',
      'en': 'Purchase total',
      'zh': '进货总计',
    },
    'grossTotalLabel': {'ru': 'Сумма', 'en': 'Subtotal', 'zh': '小计'},
    'supplierShareLabel': {
      'ru': 'Доля поставщика 10%',
      'en': 'Supplier share 10%',
      'zh': '供货方提成 10%',
    },
    'enterPriceAndQuantity': {
      'ru': 'Укажи цену и количество',
      'en': 'Enter the price and quantity',
      'zh': '请输入价格和数量',
    },
    'priceNotSpecified': {
      'ru': 'Цена не указана',
      'en': 'Price not specified',
      'zh': '未填写价格',
    },
    'priceLabel': {'ru': 'Цена', 'en': 'Price', 'zh': '价格'},
    'totalLabel': {'ru': 'Итог', 'en': 'Total', 'zh': '总计'},
    'piecesLabel': {'ru': 'Штук', 'en': 'Qty', 'zh': '件数'},
    'piecesShort': {'ru': 'шт', 'en': 'pcs', 'zh': '件'},
    'cannotOpenRoute': {
      'ru': 'Не удалось открыть маршрут.',
      'en': 'Failed to open the route.',
      'zh': '无法打开路线。',
    },
    'openRoute': {'ru': 'Открыть маршрут', 'en': 'Open route', 'zh': '打开导航'},
    'businessCardShort': {'ru': 'Визитка', 'en': 'Card', 'zh': '名片'},
    'editPurchaseTitle': {
      'ru': 'Редактировать закуп',
      'en': 'Edit purchase',
      'zh': '编辑进货',
    },
    'editPurchaseDescription': {
      'ru': 'Обнови фото, цену закупа, количество и остальные поля.',
      'en': 'Update photos, purchase price, quantity, and other fields.',
      'zh': '更新照片、进货价、数量和其它字段。',
    },
    'keepAtLeastOnePhoto': {
      'ru': 'У закупа должно остаться хотя бы одно фото.',
      'en': 'The purchase must keep at least one photo.',
      'zh': '进货记录至少要保留一张照片。',
    },
    'addAtLeastOnePhoto': {
      'ru': 'Добавь хотя бы одно фото, чтобы сохранить закуп.',
      'en': 'Add at least one photo to save the purchase.',
      'zh': '至少添加一张照片后才能保存进货。',
    },
    'favoritesHeroBadge': {'ru': 'ИЗБРАННОЕ', 'en': 'FAVORITES', 'zh': '收藏'},
    'favoritesHeroTitle': {'ru': 'Избранные', 'en': 'Favorites', 'zh': '收藏'},
    'favoritesHeroDescription': {
      'ru':
          'Сюда попадают любимые товары. Здесь можно открыть фото и отправить карточку через Telegram или другое приложение.',
      'en':
          'Favorite products appear here. You can open photos and share the card via Telegram or another app.',
      'zh': '喜欢的商品会显示在这里。你可以查看照片并通过 Telegram 或其它应用分享。',
    },
    'favoriteCountLabel': {
      'ru': 'Любимых товаров',
      'en': 'Favorite products',
      'zh': '收藏商品数',
    },
    'noFavoritesTitle': {
      'ru': 'Пока нет избранного',
      'en': 'No favorites yet',
      'zh': '还没有收藏',
    },
    'noFavoritesDescription': {
      'ru':
          'Нажми на сердечко у товара во второй вкладке, и он появится здесь.',
      'en':
          'Tap the heart on a product in the second tab and it will appear here.',
      'zh': '在第二个页面给商品点心形后，它会出现在这里。',
    },
    'favoriteRemoved': {
      'ru': 'Товар убран из избранного.',
      'en': 'Product removed from favorites.',
      'zh': '商品已从收藏中移除。',
    },
    'shareSummaryTitle': {
      'ru': 'Избранный закуп из Azaly Trade',
      'en': 'Favorite purchase from Azaly Trade',
      'zh': '来自 Azaly Trade 的收藏进货',
    },
    'shareTitle': {
      'ru': 'Azaly Trade',
      'en': 'Azaly Trade',
      'zh': 'Azaly Trade',
    },
    'shareSubject': {
      'ru': 'Избранный закуп',
      'en': 'Favorite purchase',
      'zh': '收藏进货',
    },
    'statusLabel': {'ru': 'Статус', 'en': 'Status', 'zh': '状态'},
    'photosLabel': {'ru': 'Фото', 'en': 'Photos', 'zh': '照片'},
    'shareMenuOpened': {
      'ru': 'Открылось меню «Поделиться». Можно выбрать Telegram.',
      'en': 'The share menu opened. You can choose Telegram.',
      'zh': '分享菜单已打开，你可以选择 Telegram。',
    },
    'shareMenuFailed': {
      'ru': 'Не удалось открыть меню «Поделиться».',
      'en': 'Failed to open the share menu.',
      'zh': '无法打开分享菜单。',
    },
    'favoriteBadge': {'ru': 'ИЗБРАННЫЙ', 'en': 'FAVORITE', 'zh': '已收藏'},
    'productPhotoTitle': {
      'ru': 'Фото товара',
      'en': 'Product photos',
      'zh': '商品照片',
    },
    'tapToLoadMap': {
      'ru': 'Нажми, чтобы загрузить карту',
      'en': 'Tap to load the map',
      'zh': '点击加载地图',
    },
  };
}
