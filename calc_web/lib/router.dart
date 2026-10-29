import 'package:go_router/go_router.dart';

import 'logic/calculator.dart';
import 'logic/currency.dart';
import 'screens/calculator_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/calculator',
      builder: (context, state) => const CalculatorScreen(),
      routes: [
        GoRoute(
          path: 'result',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return ResultScreen(
              title: 'Результат вычисления',
              result: calculate(q['a'], q['op'], q['b']),
              backPath: '/calculator',
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/converter',
      builder: (context, state) => const ConverterScreen(),
      routes: [
        GoRoute(
          path: 'result',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return ResultScreen(
              title: 'Результат конвертации',
              result: convert(q['from'], q['to'], q['amount']),
              backPath: '/converter',
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
);
