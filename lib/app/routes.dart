abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signInCode = '/sign-in/code';
  static const profileSetup = '/profile-setup';
  static const terms = '/terms';
  static const privacy = '/privacy';

  static const home = '/home';
  static const map = '/map';
  static const chats = '/chats';
  static const profile = '/profile';
  static const notifications = '/notifications';

  static const create = '/create';
  static const createDetails = '/create/details';
  static const createLocation = '/create/location';
  static const createReview = '/create/review';
  static const createPosted = '/create/posted';

  static String listing(String id) => '/listing/$id';
  static String claim(String listingId) => '/listing/$listingId/claim';
  static String claimSent(String listingId) => '/listing/$listingId/claim/sent';
  static String claims(String listingId) => '/listing/$listingId/claims';
  static String chat(String chatId) => '/chats/$chatId';
  static String success(String chatId) => '/success/$chatId';
}
