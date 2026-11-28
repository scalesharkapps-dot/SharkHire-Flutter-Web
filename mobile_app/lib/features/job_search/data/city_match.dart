import '../../../shared/models/job_summary.dart';

/// Pakistani cities offered in the city filter, most-searched first.
const pakistanCities = [
  'Karachi',
  'Lahore',
  'Islamabad',
  'Rawalpindi',
  'Faisalabad',
  'Peshawar',
  'Multan',
  'Hyderabad',
  'Quetta',
  'Sialkot',
  'Gujranwala',
];

/// International cities offered in the city filter. Any other city can be
/// typed into the picker.
const internationalCities = [
  'Dubai',
  'Abu Dhabi',
  'Riyadh',
  'Doha',
  'London',
  'Manchester',
  'Berlin',
  'Amsterdam',
  'Toronto',
  'New York',
  'San Francisco',
  'Singapore',
  'Kuala Lumpur',
  'Sydney',
];

/// Whether [city] is one of the Pakistani cities in the list.
bool isPakistanCity(String city) =>
    pakistanCities.any((c) => c.toLowerCase() == city.trim().toLowerCase());

/// Whether [job]'s location names [city] (e.g. "Lahore, Pakistan").
///
/// Used where the server can't filter by city: SharkHire's own job list and
/// the sample data. A Pakistani city never matches an international job of
/// the same name (Hyderabad, India is not Hyderabad, Pakistan).
bool jobInCity(JobSummary job, String city) {
  final c = city.trim().toLowerCase();
  if (c.isEmpty) return true;
  if (isPakistanCity(c) && job.isInternational) return false;
  return job.location.toLowerCase().contains(c);
}
