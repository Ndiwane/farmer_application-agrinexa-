import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  // Login
  String get appName;
  String get loginTitle;
  String get loginSubtitle;
  String get email;
  String get emailHint;
  String get password;
  String get forgotPassword;
  String get login;
  String get orContinueWith;
  String get continueWithGoogle;
  String get noAccount;
  String get registerLink;
  String get resetPassword;
  String get resetSubtitle;
  String get resetSuccess;
  String get emailAddress;
  String get sendResetLink;
  String get resetSent;
  String get backToLogin;
  String get cancel;

  // Register
  String get createAccount;
  String get registerSubtitle;
  String get firstName;
  String get lastName;
  String get phoneNumber;
  String get phoneHint;
  String get confirmPassword;
  String get register;
  String get alreadyAccount;
  String get loginLink;
  String get required;
  String get phoneRequired;
  String get phoneInvalid;
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get passwordWeak;
  String get passwordConfirmRequired;
  String get passwordNoMatch;

  // Profile
  String get profile;
  String get changePhoto;
  String get general;
  String get orderHistory;
  String get myListings;
  String get paymentSettings;
  String get pickupLocation;
  String get authenticate;
  String get changePassword;
  String get appearance;
  String get darkMode;
  String get language;
  String get support;
  String get writeComment;
  String get logOut;
  String get needHelp;
  String get currentPassword;
  String get newPassword;
  String get update;
  String get passwordChanged;
  String get passwordFailed;
  String get wrongPassword;
  String get logoutTitle;
  String get logoutConfirm;
  String get selectLanguage;
  String get english;
  String get french;

  // Nav bar
  String get navHome;
  String get navSell;
  String get navListing;
  String get navProfile;

  // Marketplace
  String get findFreshProducts;
  String get searchHint;
  String get categories;
  String get recommendedForYou;
  String get noProductsYet;
  String get beFirstToList;
  String get noProductsMatchFilters;
  String get clearFilters;
  String get filters;
  String get clearAll;
  String get priceRange;
  String get locationFilter;
  String get sortBy;
  String get applyFilters;
  String get min;
  String get max;
  String get newest;
  String get priceLowHigh;
  String get priceHighLow;

  // Chat
  String get chats;
  String get status;
  String get myStatus;
  String get addStatus;
  String get photoStatus;
  String get photoStatusSubtitle;
  String get textStatus;
  String get textStatusSubtitle;
  String get noConversationsYet;
  String get startChattingHint;

  // Message
  String get typeMessage;
  String get failedToSend;
  String get camera;
  String get gallery;
  String get deleteMessage;
  String get deleteMessageConfirm;
  String get messageDeleted;
  String get online;
  String get offline;
  String get delete;

  // Orders
  String get orders;
  String get myOrders;
  String get receivedOrders;
  String get noOrdersYet;
  String get noOrdersReceived;
  String get confirmDelivery;
  String get confirmReceivedQuestion;
  String get iReceivedMyOrder;
  String get contactSeller;
  String get phoneNotAvailable;
  String get copy;
  String get whatsApp;
  String get phoneCopied;
  String get whatsAppCopied;
  String get confirmOrder;
  String get markAsShipped;
  String get waitingBuyerConfirm;
  String get orderCompleted;
  String get orderPlaced;
  String get orderConfirmed;
  String get orderShipped;
  String get orderDelivered;
  String get thankYouConfirming;

  // Notifications
  String get notifications;
  String get noNotificationsYet;
  String get notificationsHint;
  String get clearAllNotifications;
  String get clearNotificationsConfirm;
  String get allNotificationsCleared;

  // Sell product
  String get sellProduct;
  String get cropName;
  String get categoryLabel;
  String get availableQuantity;
  String get locationLabel;
  String get descriptionLabel;
  String get pricePerUnit;
  String get listProduct;
  String get selectImageSource;
  String get takePhoto;
  String get chooseFromGallery;
  String get tapToAddImage;
  String get pleaseSelectCategory;
  String get productListedSuccess;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'fr': return AppLocalizationsFr();
    case 'en': return AppLocalizationsEn();
  }
  throw FlutterError('AppLocalizations.delegate failed to load unsupported locale "$locale".');
}