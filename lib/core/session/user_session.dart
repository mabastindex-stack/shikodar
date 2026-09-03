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

  bool get isAgency => role == AccountRole.agency;
  bool get isCompany => role == AccountRole.company;
  bool get isComplex => role == AccountRole.complex;
  bool get isAdmin => role == AccountRole.admin;

  void setRole(AccountRole newRole) {
    role = newRole;
    notifyListeners();
  }

  /// Successful login/registration — called from `LoginScreen`/`OtpScreen`.
  void logIn(AccountRole newRole) {
    role = newRole;
    isLoggedIn = true;
    notifyListeners();
  }

  void logOut() {
    role = AccountRole.client;
    isLoggedIn = false;
    notifyListeners();
  }

  /// Back-compat for older call sites that only distinguished agency/client.
  void setAgency({required bool asAgency}) {
    role = asAgency ? AccountRole.agency : AccountRole.client;
    notifyListeners();
  }
}
