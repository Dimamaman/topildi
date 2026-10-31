abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const profileSetup = '/profile-setup';
  static const terms = '/terms';
  static const privacy = '/privacy';

  static const home = '/home';
  static const map = '/map';
  static const chats = '/chats';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const myListings = '/my-listings';
  static const blocked = '/blocked';

  /// "Egasiga qaytdi" as stories; the items themselves come in `extra`.
  static const returnedStories = '/returned';

  static const create = '/create';
  static const createDetails = '/create/details';
  static const createLocation = '/create/location';
  static const createReview = '/create/review';
  static const createPosted = '/create/posted';

  /// Edit an own listing: Review of the loaded listing, steps open from it.
  static String editListing(String id) => '/create/edit/$id';

  static String listing(String id) => '/listing/$id';
  static String claim(String listingId) => '/listing/$listingId/claim';
  static String claimSent(String listingId) => '/listing/$listingId/claim/sent';
  static String claims(String listingId) => '/listing/$listingId/claims';
  static String chat(String chatId) => '/chats/$chatId';
  static String success(String chatId) => '/success/$chatId';
}
