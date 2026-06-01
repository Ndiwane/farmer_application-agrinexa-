import 'package:flutter/material.dart';
import '../main.dart';

/// Simple translation class using dictionary approach
/// Usage: final t = AppTranslations.of(context);
///        Text(t.hello)
class AppTranslations {
  final String lang;
  AppTranslations(this.lang);

  /// Get translations for current app language
  factory AppTranslations.of(BuildContext context) {
    final lang = AgriNexaApp.of(context)?.language ?? 'en';
    return AppTranslations(lang);
  }

  String _t(String key) =>
      _strings[lang]?[key] ?? _strings['en']![key] ?? key;

  // ── General ────────────────────────────────────────────────────────────
  String get hello => _t('hello');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get copy => _t('copy');
  String get yes => _t('yes');
  String get no => _t('no');

  // ── Marketplace ────────────────────────────────────────────────────────
  String get findFreshProducts => _t('findFreshProducts');
  String get searchHint => _t('searchHint');
  String get categories => _t('categories');
  String get recommendedForYou => _t('recommendedForYou');
  String get noProductsYet => _t('noProductsYet');
  String get beFirstToList => _t('beFirstToList');
  String get noProductsMatchFilters => _t('noProductsMatchFilters');
  String get clearFilters => _t('clearFilters');
  String get filters => _t('filters');
  String get clearAll => _t('clearAll');
  String get priceRange => _t('priceRange');
  String get locationFilter => _t('locationFilter');
  String get sortBy => _t('sortBy');
  String get applyFilters => _t('applyFilters');
  String get min => _t('min');
  String get max => _t('max');
  String get newest => _t('newest');
  String get priceLowHigh => _t('priceLowHigh');
  String get priceHighLow => _t('priceHighLow');

  // ── Chat ───────────────────────────────────────────────────────────────
  String get chats => _t('chats');
  String get status => _t('status');
  String get myStatus => _t('myStatus');
  String get addStatus => _t('addStatus');
  String get photoStatus => _t('photoStatus');
  String get photoStatusSubtitle => _t('photoStatusSubtitle');
  String get textStatus => _t('textStatus');
  String get textStatusSubtitle => _t('textStatusSubtitle');
  String get noConversationsYet => _t('noConversationsYet');
  String get startChattingHint => _t('startChattingHint');

  // ── Message ────────────────────────────────────────────────────────────
  String get typeMessage => _t('typeMessage');
  String get failedToSend => _t('failedToSend');
  String get camera => _t('camera');
  String get gallery => _t('gallery');
  String get deleteMessage => _t('deleteMessage');
  String get deleteMessageConfirm => _t('deleteMessageConfirm');
  String get messageDeleted => _t('messageDeleted');
  String get online => _t('online');
  String get offline => _t('offline');

  // ── Orders ─────────────────────────────────────────────────────────────
  String get orders => _t('orders');
  String get myOrders => _t('myOrders');
  String get receivedOrders => _t('receivedOrders');
  String get noOrdersYet => _t('noOrdersYet');
  String get noOrdersReceived => _t('noOrdersReceived');
  String get confirmDelivery => _t('confirmDelivery');
  String get confirmReceivedQuestion => _t('confirmReceivedQuestion');
  String get iReceivedMyOrder => _t('iReceivedMyOrder');
  String get contactSeller => _t('contactSeller');
  String get phoneNotAvailable => _t('phoneNotAvailable');
  String get whatsApp => _t('whatsApp');
  String get phoneCopied => _t('phoneCopied');
  String get whatsAppCopied => _t('whatsAppCopied');
  String get confirmOrder => _t('confirmOrder');
  String get markAsShipped => _t('markAsShipped');
  String get waitingBuyerConfirm => _t('waitingBuyerConfirm');
  String get orderCompleted => _t('orderCompleted');
  String get orderPlaced => _t('orderPlaced');
  String get orderConfirmed => _t('orderConfirmed');
  String get orderShipped => _t('orderShipped');
  String get orderDelivered => _t('orderDelivered');
  String get thankYouConfirming => _t('thankYouConfirming');
  String get buyerNotified => _t('buyerNotified');
  String orderMarkedAs(String status) =>
      '${_t('orderMarkedAs')} $status! ${_t('buyerNotified')}';

  // ── Notifications ──────────────────────────────────────────────────────
  String get notifications => _t('notifications');
  String get noNotificationsYet => _t('noNotificationsYet');
  String get notificationsHint => _t('notificationsHint');
  String get clearAllNotifications => _t('clearAllNotifications');
  String get clearNotificationsConfirm => _t('clearNotificationsConfirm');
  String get allNotificationsCleared => _t('allNotificationsCleared');

  // ── Sell Product ───────────────────────────────────────────────────────
  String get sellProduct => _t('sellProduct');
  String get cropName => _t('cropName');
  String get categoryLabel => _t('categoryLabel');
  String get availableQuantity => _t('availableQuantity');
  String get locationLabel => _t('locationLabel');
  String get descriptionLabel => _t('descriptionLabel');
  String get pricePerUnit => _t('pricePerUnit');
  String get listProduct => _t('listProduct');
  String get selectImageSource => _t('selectImageSource');
  String get takePhoto => _t('takePhoto');
  String get chooseFromGallery => _t('chooseFromGallery');
  String get tapToAddImage => _t('tapToAddImage');
  String get pleaseSelectCategory => _t('pleaseSelectCategory');
  String get productListedSuccess => _t('productListedSuccess');
  String get pleaseAddImage => _t('pleaseAddImage');
  String get cropNameRequired => _t('cropNameRequired');
  String get quantityRequired => _t('quantityRequired');
  String get enterValidNumber => _t('enterValidNumber');
  String get mustBeGreaterThanZero => _t('mustBeGreaterThanZero');
  String get locationRequired => _t('locationRequired');
  String get descriptionRequired => _t('descriptionRequired');
  String get descriptionTooShort => _t('descriptionTooShort');
  String get priceRequired => _t('priceRequired');
  String get enterValidPrice => _t('enterValidPrice');
  String get priceMustBePositive => _t('priceMustBePositive');

  // ── Dictionary ─────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // General
      'hello': 'Hello',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'copy': 'Copy',
      'yes': 'Yes',
      'no': 'No',

      // Marketplace
      'findFreshProducts': 'Find fresh farm products',
      'searchHint': 'Search by name or location...',
      'categories': 'Categories',
      'recommendedForYou': '🔥 Recommended For You',
      'noProductsYet': 'No products yet',
      'beFirstToList': 'Be the first to list a product!',
      'noProductsMatchFilters': 'No products match your filters',
      'clearFilters': 'Clear Filters',
      'filters': '🎛️ Filters',
      'clearAll': 'Clear All',
      'priceRange': '💰 Price Range (FCFA)',
      'locationFilter': '📍 Location',
      'sortBy': '↕️ Sort By',
      'applyFilters': 'Apply Filters',
      'min': 'Min',
      'max': 'Max',
      'newest': 'Newest',
      'priceLowHigh': 'Price: Low→High',
      'priceHighLow': 'Price: High→Low',

      // Chat
      'chats': 'Chats',
      'status': 'Status',
      'myStatus': 'My Status',
      'addStatus': 'Add Status',
      'photoStatus': 'Photo Status',
      'photoStatusSubtitle': 'Share a photo from your gallery',
      'textStatus': 'Text Status',
      'textStatusSubtitle': 'Share a text with colored background',
      'noConversationsYet': 'No conversations yet',
      'startChattingHint': 'Contact a seller from the marketplace to start chatting!',

      // Message
      'typeMessage': 'Type a message...',
      'failedToSend': 'Failed to send message',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'deleteMessage': 'Delete Message',
      'deleteMessageConfirm': 'Delete this message?',
      'messageDeleted': 'Message deleted',
      'online': 'Online',
      'offline': 'Offline',

      // Orders
      'orders': 'Orders',
      'myOrders': 'My Orders',
      'receivedOrders': 'Received Orders',
      'noOrdersYet': 'You have not placed any orders yet.',
      'noOrdersReceived': 'No orders received yet.',
      'confirmDelivery': 'Confirm Delivery',
      'confirmReceivedQuestion': 'Are you sure you received your order in good condition?',
      'iReceivedMyOrder': 'I Received My Order ✅',
      'contactSeller': 'Contact Seller',
      'phoneNotAvailable': 'Phone not available',
      'whatsApp': 'WhatsApp',
      'phoneCopied': 'Phone number copied!',
      'whatsAppCopied': 'Number copied! Open WhatsApp and paste to chat.',
      'confirmOrder': 'Confirm Order',
      'markAsShipped': 'Mark as Shipped 🚚',
      'waitingBuyerConfirm': 'Waiting for buyer to confirm delivery...',
      'orderCompleted': 'Order completed successfully! 🎉',
      'orderPlaced': 'Placed',
      'orderConfirmed': 'Confirmed',
      'orderShipped': 'Shipped',
      'orderDelivered': 'Delivered',
      'thankYouConfirming': 'Thank you for confirming! 🎉',
      'buyerNotified': 'Buyer notified.',
      'orderMarkedAs': 'Order marked as',

      // Notifications
      'notifications': 'Notifications',
      'noNotificationsYet': 'No notifications yet',
      'notificationsHint': 'You\'ll see updates about orders and messages here',
      'clearAllNotifications': 'Clear All Notifications?',
      'clearNotificationsConfirm': 'This will delete all your notifications permanently.',
      'allNotificationsCleared': 'All notifications cleared',

      // Sell Product
      'sellProduct': 'Sell Product',
      'cropName': 'Crop Name',
      'categoryLabel': 'Category',
      'availableQuantity': 'Available Quantity',
      'locationLabel': 'Location',
      'descriptionLabel': 'Description',
      'pricePerUnit': 'Price per Unit',
      'listProduct': 'List Product',
      'selectImageSource': 'Select Image Source',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'tapToAddImage': 'Tap to add product image',
      'pleaseSelectCategory': 'Please select a product category',
      'productListedSuccess': 'Product listed successfully!',
      'pleaseAddImage': 'Please add a product image',
      'cropNameRequired': 'Crop name is required',
      'quantityRequired': 'Required',
      'enterValidNumber': 'Enter a valid number',
      'mustBeGreaterThanZero': 'Must be > 0',
      'locationRequired': 'Location is required',
      'descriptionRequired': 'Description is required',
      'descriptionTooShort': 'Description too short',
      'priceRequired': 'Price is required',
      'enterValidPrice': 'Enter a valid price',
      'priceMustBePositive': 'Price must be greater than 0',
    },

    'fr': {
      // General
      'hello': 'Bonjour',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'copy': 'Copier',
      'yes': 'Oui',
      'no': 'Non',

      // Marketplace
      'findFreshProducts': 'Trouvez des produits agricoles frais',
      'searchHint': 'Rechercher par nom ou lieu...',
      'categories': 'Catégories',
      'recommendedForYou': '🔥 Recommandé Pour Vous',
      'noProductsYet': 'Pas encore de produits',
      'beFirstToList': 'Soyez le premier à lister un produit!',
      'noProductsMatchFilters': 'Aucun produit ne correspond aux filtres',
      'clearFilters': 'Effacer les filtres',
      'filters': '🎛️ Filtres',
      'clearAll': 'Tout effacer',
      'priceRange': '💰 Plage de prix (FCFA)',
      'locationFilter': '📍 Lieu',
      'sortBy': '↕️ Trier par',
      'applyFilters': 'Appliquer les filtres',
      'min': 'Min',
      'max': 'Max',
      'newest': 'Plus récent',
      'priceLowHigh': 'Prix: Croissant',
      'priceHighLow': 'Prix: Décroissant',

      // Chat
      'chats': 'Discussions',
      'status': 'Statut',
      'myStatus': 'Mon Statut',
      'addStatus': 'Ajouter un Statut',
      'photoStatus': 'Statut Photo',
      'photoStatusSubtitle': 'Partagez une photo de votre galerie',
      'textStatus': 'Statut Texte',
      'textStatusSubtitle': 'Partagez un texte avec fond coloré',
      'noConversationsYet': 'Pas encore de conversations',
      'startChattingHint': 'Contactez un vendeur depuis le marché pour commencer à chatter!',

      // Message
      'typeMessage': 'Tapez un message...',
      'failedToSend': 'Échec de l\'envoi du message',
      'camera': 'Caméra',
      'gallery': 'Galerie',
      'deleteMessage': 'Supprimer le message',
      'deleteMessageConfirm': 'Supprimer ce message?',
      'messageDeleted': 'Message supprimé',
      'online': 'En ligne',
      'offline': 'Hors ligne',

      // Orders
      'orders': 'Commandes',
      'myOrders': 'Mes Commandes',
      'receivedOrders': 'Commandes Reçues',
      'noOrdersYet': 'Vous n\'avez pas encore passé de commandes.',
      'noOrdersReceived': 'Aucune commande reçue.',
      'confirmDelivery': 'Confirmer la livraison',
      'confirmReceivedQuestion': 'Êtes-vous sûr d\'avoir reçu votre commande en bon état?',
      'iReceivedMyOrder': 'J\'ai reçu ma commande ✅',
      'contactSeller': 'Contacter le vendeur',
      'phoneNotAvailable': 'Téléphone non disponible',
      'whatsApp': 'WhatsApp',
      'phoneCopied': 'Numéro copié!',
      'whatsAppCopied': 'Numéro copié! Ouvrez WhatsApp et collez pour chatter.',
      'confirmOrder': 'Confirmer la commande',
      'markAsShipped': 'Marquer comme expédié 🚚',
      'waitingBuyerConfirm': 'En attente de la confirmation de l\'acheteur...',
      'orderCompleted': 'Commande terminée avec succès! 🎉',
      'orderPlaced': 'Passée',
      'orderConfirmed': 'Confirmée',
      'orderShipped': 'Expédiée',
      'orderDelivered': 'Livrée',
      'thankYouConfirming': 'Merci pour votre confirmation! 🎉',
      'buyerNotified': 'Acheteur notifié.',
      'orderMarkedAs': 'Commande marquée comme',

      // Notifications
      'notifications': 'Notifications',
      'noNotificationsYet': 'Pas encore de notifications',
      'notificationsHint': 'Vous verrez ici les mises à jour sur les commandes et messages',
      'clearAllNotifications': 'Effacer toutes les notifications?',
      'clearNotificationsConfirm': 'Cela supprimera définitivement toutes vos notifications.',
      'allNotificationsCleared': 'Toutes les notifications effacées',

      // Sell Product
      'sellProduct': 'Vendre un produit',
      'cropName': 'Nom de la culture',
      'categoryLabel': 'Catégorie',
      'availableQuantity': 'Quantité disponible',
      'locationLabel': 'Lieu',
      'descriptionLabel': 'Description',
      'pricePerUnit': 'Prix par unité',
      'listProduct': 'Mettre en vente',
      'selectImageSource': 'Sélectionner la source de l\'image',
      'takePhoto': 'Prendre une photo',
      'chooseFromGallery': 'Choisir depuis la galerie',
      'tapToAddImage': 'Appuyez pour ajouter une image',
      'pleaseSelectCategory': 'Veuillez sélectionner une catégorie',
      'productListedSuccess': 'Produit mis en vente avec succès!',
      'pleaseAddImage': 'Veuillez ajouter une image du produit',
      'cropNameRequired': 'Le nom de la culture est requis',
      'quantityRequired': 'Requis',
      'enterValidNumber': 'Entrez un nombre valide',
      'mustBeGreaterThanZero': 'Doit être > 0',
      'locationRequired': 'Le lieu est requis',
      'descriptionRequired': 'La description est requise',
      'descriptionTooShort': 'Description trop courte',
      'priceRequired': 'Le prix est requis',
      'enterValidPrice': 'Entrez un prix valide',
      'priceMustBePositive': 'Le prix doit être supérieur à 0',
    },
  };
}