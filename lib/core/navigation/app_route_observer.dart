import 'package:flutter/material.dart';

/// App-wide route observer, registered once on MaterialApp. Lets any screen
/// that needs to react to something being pushed on top of it (or popped
/// back to it) subscribe via RouteAware — used by ReelsScreen to pause its
/// video/audio the moment another screen covers it (e.g. tapping through to
/// a listing or agency profile from a reel), and resume on return.
final routeObserver = RouteObserver<PageRoute>();
