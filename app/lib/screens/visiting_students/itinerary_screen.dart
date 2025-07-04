import 'package:common/models/generic/address.dart';
import 'package:common/models/itineraries/itinerary.dart';
import 'package:common/models/itineraries/visiting_priority.dart';
import 'package:common/models/itineraries/waypoint.dart';
import 'package:common_flutter/providers/enterprises_provider.dart';
import 'package:common_flutter/providers/internships_provider.dart';
import 'package:common_flutter/providers/school_boards_provider.dart';
import 'package:common_flutter/widgets/custom_date_picker.dart';
import 'package:crcrme_banque_stages/common/provider_helpers/itineraries_helpers.dart';
import 'package:crcrme_banque_stages/common/provider_helpers/students_helpers.dart';
import 'package:crcrme_banque_stages/screens/visiting_students/widgets/routing_map.dart';
import 'package:crcrme_banque_stages/screens/visiting_students/widgets/waypoint_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ItineraryMainScreen extends StatefulWidget {
  const ItineraryMainScreen({super.key});

  static const route = '/itineraries';

  @override
  State<ItineraryMainScreen> createState() => _ItineraryMainScreenState();
}

class _ItineraryMainScreenState extends State<ItineraryMainScreen> {
  final List<Waypoint> _waypoints = [];
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<T?> _waitFor<T>(
      Function(BuildContext context, {bool listen}) providerOf) async {
    var provided = providerOf(context, listen: false);
    while (provided.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return null;
      provided = providerOf(context, listen: false);
    }
    return provided;
  }

  Future<bool> _fillAllWaypoints() async {
    final internships = InternshipsProvider.of(context, listen: false);

    var school = SchoolBoardsProvider.of(context, listen: false).mySchool;
    if (!mounted || school == null) return false;

    final enterprises =
        await _waitFor<EnterprisesProvider>(EnterprisesProvider.of);
    if (!mounted || enterprises == null) return false;

    if (!mounted) return false;

    final students = {
      ...StudentsHelpers.mySupervizedStudents(context,
          listen: false, activeOnly: true)
    };
    if (!mounted) return false;

    // Add the school as the first waypoint
    _waypoints.clear();
    _waypoints.add(
      await Waypoint.fromAddress(
        title: 'École',
        address: school.address,
        priority: VisitingPriority.school,
      ),
    );

    // Get the students from the registered students, but we copy them so
    // we don't mess with them
    for (final student in students) {
      final studentInternships = internships.byStudentId(student.id);
      if (studentInternships.isEmpty) continue;
      final internship = studentInternships.last;

      final enterprise = enterprises.fromIdOrNull(internship.enterpriseId);
      if (enterprise == null) continue;

      _waypoints.add(
        await Waypoint.fromAddress(
          title: '${student.firstName} ${student.lastName[0]}.',
          subtitle: enterprise.name,
          address: enterprise.address ?? Address.empty,
          priority: internship.visitingPriority,
        ),
      );
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 7,
      minThumbLength: 75,
      thumbColor: Theme.of(context).primaryColor,
      radius: const Radius.circular(20),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ScrollPhysics(),
        child: FutureBuilder(
          future: _fillAllWaypoints(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) const CircularProgressIndicator();

            return ItineraryScreen(waypoints: _waypoints);
          },
        ),
      ),
    );
  }
}

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key, required this.waypoints});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
  final List<Waypoint> waypoints;
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late final _routingController = RoutingController(
      destinations: widget.waypoints,
      itinerary: currentItinerary,
      onItineraryChanged: _onItineraryChanged);

  void _onItineraryChanged() {
    setState(() {});
  }

  final _itineraries = <DateTime, Itinerary>{};
  void _selectItinerary(DateTime date) {
    if (_itineraries[date] == null) {
      _itineraries[date] =
          ItinerariesHelpers.fromDate(context, date)?.copyWith() ??
              Itinerary(date: date);
    }
    _routingController.setItinerary(context, _itineraries[date]!);
  }

  late DateTime _currentDate;
  Itinerary get currentItinerary {
    if (_itineraries[_currentDate] == null) _selectItinerary(_currentDate);
    return _itineraries[_currentDate]!;
  }

  @override
  void initState() {
    super.initState();

    final date = DateTime.now();
    _currentDate = DateTime(date.year, date.month, date.day);
    _selectItinerary(_currentDate);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) =>
          didPop ? _routingController.saveItinerary(context) : null,
      child: Column(
        children: [
          _showDate(),
          if (widget.waypoints.isNotEmpty) _map(),
          if (widget.waypoints.isEmpty) const CircularProgressIndicator(),
          _Distance(_routingController.distances, itinerary: currentItinerary),
          const SizedBox(height: 20),
          _studentsToVisitWidget(context),
        ],
      ),
    );
  }

  Widget _showDate() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
            'Faire l\'itinéraire du\n${DateFormat('d MMMM yyyy', 'fr_CA').format(_currentDate)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.calendar_month,
                        size: 30,
                      ),
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDatePicker() async {
    final newDate = await showCustomDatePicker(
        context: context,
        initialDate: _currentDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 31)));

    if (newDate == null || !mounted) return;

    // Keep only granularity of days
    _currentDate = DateTime(newDate.year, newDate.month, newDate.day);
    _selectItinerary(_currentDate);

    setState(() {});
  }

  Widget _map() {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.5,
        child: RoutingMap(
          controller: _routingController,
          waypoints: widget.waypoints,
          itinerary: currentItinerary,
          onItineraryChanged: (_) => setState(() {}),
        ));
  }

  Widget _studentsToVisitWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (currentItinerary.isNotEmpty)
          ReorderableListView.builder(
            onReorder: (oldIndex, newIndex) {
              currentItinerary.move(oldIndex, newIndex);
              setState(() {});
            },
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final way = currentItinerary[index];
              return WaypointCard(
                key: ValueKey(way.id),
                name: way.title,
                waypoint: way,
                onDelete: () => _routingController.removeFromItinerary(index),
              );
            },
            itemCount: currentItinerary.length,
          ),
      ],
    );
  }
}

class _Distance extends StatefulWidget {
  const _Distance(this.distances, {required this.itinerary});

  final List<double>? distances;
  final Itinerary itinerary;

  @override
  State<_Distance> createState() => __DistanceState();
}

class __DistanceState extends State<_Distance> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.distances == null) return Container();

    return GestureDetector(
      onTap: () {
        _isExpanded = !_isExpanded;
        setState(() {});
      },
      behavior: HitTestBehavior.opaque, // Make the full box clickable
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(
                      'Kilométrage\u00a0: '
                      '${(widget.distances!.isEmpty ? 0 : widget.distances!.reduce((a, b) => a + b).toDouble() / 1000).toStringAsFixed(1)}km',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).disabledColor),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
            if (_isExpanded) ..._distancesTo(widget.distances!)
          ],
        ),
      ),
    );
  }

  List<Widget> _distancesTo(List<double?> distances) {
    List<Widget> out = [];
    if (distances.length + 1 != widget.itinerary.length) return out;

    for (int i = 0; i < distances.length; i++) {
      final distance = distances[i];
      final startingPoint = widget.itinerary[i];
      final endingPoint = widget.itinerary[i + 1];

      out.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
        child: Text(
            '${startingPoint.title} / ${endingPoint.title} : ${(distance! / 1000).toStringAsFixed(1)}km'),
      ));
    }

    return out;
  }
}
