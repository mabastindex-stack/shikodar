import 'package:flutter/material.dart';

/// - `agency`: a broker/dealer selling or renting individual scattered
///   listings (houses, villas, land, shops) across the city.
/// - `company`: a holding/development firm. May own one or more `complex`
///   accounts (shows them on its own public profile), but doesn't itself
///   have to run a complex.
/// - `complex`: a residential complex (مجمع سکنی) — manages its own units
///   as one Project ("its own city"). A `complex` MAY have a parent
///   `company` that created it, or may be fully independent — the two are
///   separate account types precisely because that link is optional.
enum AccountRole { client, agency, company, complex, admin }

/// Tracks which kind of account is signed in. Set at login/register based
/// on the role the person picked, and read by any screen that needs to
/// show, hide, or gate features by account type (e.g. only business roles
/// can post listings/projects/reels, only admins can create accounts).
class UserSession extends ChangeNotifier {
  AccountRole role = AccountRole.client;

  /// Whether anyone has actually signed in this session. The app is
  /// browsable as a guest (client-shaped UI, `role` stays `client`) without
  /// this ever being true — only the profile tab's login/register flow
  /// sets it, gating account-only screens without gating browsing itself.
  bool isLoggedIn = false;

  /// The signed-in account's real name from the server — null while a
  /// guest, so screens fall back to a generic label instead of a stale
  /// placeholder.
  String? name;

  /// The signed-in account's own agency id, if it's a business account —
  /// lets a public profile page (AgencyProfileScreen/DeveloperProfileScreen)
  /// recognize when it's showing the signed-in user's own business.
  String? agencyId;

  /// The business's package tier and contract expiry — null for a client.
  /// Read by ProfileScreen's package-usage card instead of a hardcoded
  /// "Enterprise" label and a fake expiry date.
  String? tier;
  DateTime? contractEndDate;

  /// The business's own public profile — logo shown as the account
  /// avatar, phone/whatsapp shown on ProfileScreen's contact card. Null
  /// for a client, and null for a business that hasn't set them yet.
  String? logoUrl;
  String? agencyPhone;
  String? agencyWhatsapp;

  bool get isAgency => role == AccountRole.agency;
  bool get isCompany => role == AccountRole.company;
  bool get isComplex => role == AccountRole.complex;
  bool get isAdmin => role == AccountRole.admin;

  void setRole(AccountRole newRole) {
    role = newRole;
    notifyListeners();
  }

  /// Successful login/registration — called from `LoginScreen`/`OtpScreen`.
  void logIn(
    AccountRole newRole, {
    String? name,
    String? agencyId,
    String? tier,
    DateTime? contractEndDate,
    String? logoUrl,
    String? agencyPhone,
    String? agencyWhatsapp,
  }) {
    role = newRole;
    isLoggedIn = true;
    this.name = name;
    this.agencyId = agencyId;
    this.tier = tier;
    this.contractEndDate = contractEndDate;
    this.logoUrl = logoUrl;
    this.agencyPhone = agencyPhone;
    this.agencyWhatsapp = agencyWhatsapp;
    notifyListeners();
  }

  void logOut() {
    role = AccountRole.client;
    isLoggedIn = false;
    name = null;
    agencyId = null;
    tier = null;
    contractEndDate = null;
    logoUrl = null;
    agencyPhone = null;
    agencyWhatsapp = null;
    notifyListeners();
  }

  /// Applied after ProfileScreen saves a logo/phone/whatsapp change, so
  /// every screen reading these values (this tab, package cards, etc.)
  /// updates immediately without a fresh /auth/me round trip.
  void updateAgencyProfile({String? logoUrl, String? agencyPhone, String? agencyWhatsapp}) {
    if (logoUrl != null) this.logoUrl = logoUrl;
    if (agencyPhone != null) this.agencyPhone = agencyPhone;
    if (agencyWhatsapp != null) this.agencyWhatsapp = agencyWhatsapp;
    notifyListeners();
  }

  /// Back-compat for older call sites that only distinguished agency/client.
  void setAgency({required bool asAgency}) {
    role = asAgency ? AccountRole.agency : AccountRole.client;
    notifyListeners();
  }
}
