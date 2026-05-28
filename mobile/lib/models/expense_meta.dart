import '../localization/app_strings.dart';

class ExpenseAccountingType {
  static const notSelected = 'not_selected';
  static const product = 'product';
  static const personal = 'personal';

  static const values = [notSelected, product, personal];
}

class ExpenseAccountingChannel {
  static const notSelected = 'not_selected';
  static const dk = 'dk';
  static const pocket = 'pocket';

  static const values = [notSelected, dk, pocket];
}

class ExpenseInputCurrency {
  static const cny = 'CNY';
  static const usd = 'USD';
  static const uzs = 'UZS';

  static const values = [cny, usd, uzs];
}

String normalizeExpenseAccountingType(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case ExpenseAccountingType.product:
    case ExpenseAccountingType.personal:
      return value!.trim().toLowerCase();
    default:
      return ExpenseAccountingType.notSelected;
  }
}

String normalizeExpenseAccountingChannel(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case ExpenseAccountingChannel.dk:
    case ExpenseAccountingChannel.pocket:
      return value!.trim().toLowerCase();
    default:
      return ExpenseAccountingChannel.notSelected;
  }
}

String normalizeExpenseInputCurrency(String? value) {
  switch ((value ?? ExpenseInputCurrency.cny).trim().toUpperCase()) {
    case ExpenseInputCurrency.usd:
    case ExpenseInputCurrency.uzs:
      return value!.trim().toUpperCase();
    default:
      return ExpenseInputCurrency.cny;
  }
}

String expenseAccountingTypeLabel(String value, AppLanguage language) {
  switch (normalizeExpenseAccountingType(value)) {
    case ExpenseAccountingType.product:
      switch (language) {
        case AppLanguage.ru:
          return 'Расход на товар';
        case AppLanguage.en:
          return 'Product expense';
        case AppLanguage.zh:
          return '商品支出';
      }
    case ExpenseAccountingType.personal:
      switch (language) {
        case AppLanguage.ru:
          return 'Личный расход';
        case AppLanguage.en:
          return 'Personal expense';
        case AppLanguage.zh:
          return '个人支出';
      }
    default:
      switch (language) {
        case AppLanguage.ru:
          return 'Не выбрано';
        case AppLanguage.en:
          return 'Not selected';
        case AppLanguage.zh:
          return '未选择';
      }
  }
}

String expenseAccountingChannelLabel(String value, AppLanguage language) {
  switch (normalizeExpenseAccountingChannel(value)) {
    case ExpenseAccountingChannel.dk:
      return 'Д/К';
    case ExpenseAccountingChannel.pocket:
      switch (language) {
        case AppLanguage.ru:
          return 'Карман';
        case AppLanguage.en:
          return 'Pocket';
        case AppLanguage.zh:
          return '口袋';
      }
    default:
      switch (language) {
        case AppLanguage.ru:
          return 'Не выбрано';
        case AppLanguage.en:
          return 'Not selected';
        case AppLanguage.zh:
          return '未选择';
      }
  }
}

String expenseInputCurrencyLabel(String value) {
  return normalizeExpenseInputCurrency(value);
}

String expenseAccountingTypeFieldLabel(AppLanguage language) {
  switch (language) {
    case AppLanguage.ru:
      return 'Тип учёта';
    case AppLanguage.en:
      return 'Accounting type';
    case AppLanguage.zh:
      return '记账类型';
  }
}

String expenseAccountingChannelFieldLabel(AppLanguage language) {
  switch (language) {
    case AppLanguage.ru:
      return 'Канал учёта';
    case AppLanguage.en:
      return 'Accounting channel';
    case AppLanguage.zh:
      return '记账渠道';
  }
}

String expenseInputCurrencyFieldLabel(AppLanguage language) {
  switch (language) {
    case AppLanguage.ru:
      return 'Валюта ввода';
    case AppLanguage.en:
      return 'Input currency';
    case AppLanguage.zh:
      return '输入货币';
  }
}

String expenseAmountFieldLabel(AppLanguage language, String currency) {
  switch (normalizeExpenseInputCurrency(currency)) {
    case ExpenseInputCurrency.usd:
      switch (language) {
        case AppLanguage.ru:
          return 'Сумма (USD, \$)';
        case AppLanguage.en:
          return 'Amount (USD, \$)';
        case AppLanguage.zh:
          return '金额（美元 \$）';
      }
    case ExpenseInputCurrency.uzs:
      switch (language) {
        case AppLanguage.ru:
          return 'Сумма (UZS)';
        case AppLanguage.en:
          return 'Amount (UZS)';
        case AppLanguage.zh:
          return '金额（UZS）';
      }
    default:
      switch (language) {
        case AppLanguage.ru:
          return 'Сумма (CNY, ¥)';
        case AppLanguage.en:
          return 'Amount (CNY, ¥)';
        case AppLanguage.zh:
          return '金额（人民币 ¥）';
      }
  }
}
