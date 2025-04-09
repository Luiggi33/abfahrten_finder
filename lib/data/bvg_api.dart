import 'dart:convert';

import 'package:abfahrt_finder/provider/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

Future<List<TransitStop>> fetchBVGStopData(String apiURL, double latitude, double longitude, int searchRadius) async {
  final response = await http.get(
    Uri.parse(
      "$apiURL/locations/nearby?latitude=$latitude&longitude=$longitude&distance=$searchRadius&linesOfStops=true",
    ),
  );

  if (response.statusCode == 200) {
    List<dynamic> parsedListJson = jsonDecode(response.body);
    return parsedListJson.map((json) => TransitStop.fromJson(json)).toList();
  } else {
    throw Exception("Failed to load BVG stop data");
  }
}

Future<List<Trip>> fetchBVGArrivalData(String apiURL, int stopID, int duration, int maxResults) async {
  final response = await http.get(
    Uri.parse(
        "$apiURL/stops/$stopID/arrivals?duration=$duration&results=$maxResults"
    ),
  );

  if (response.statusCode == 200) {
    List<dynamic> parsed = jsonDecode(response.body)["arrivals"];
    return parsed.map<Trip>((json) => Trip.fromJson(json)).toList();
  } else {
    throw Exception("Failed to load BVG arrival data");
  }
}

String trimZero(double num) {
  String tmp = num.toString();
  if (!tmp.contains('.')) {
    return tmp;
  }
  while (tmp.endsWith('0')) {
    tmp = tmp.substring(0, tmp.length - 1);
  }
  if (tmp.endsWith('.')) {
    tmp = tmp.substring(0, tmp.length - 1);
  }
  return tmp;
}

class Trip {
  final String tripId;
  final TripStop stop;
  final String? when;
  final String? plannedWhen;
  final String? prognosedWhen;
  final int? delay;
  final String? platform;
  final String? plannedPlatform;
  final String? prognosedPlatform;
  final String? prognosisType;
  final String? direction;
  final String? provenance;
  final Line line;
  final List<Remark> remarks;
  final TripStop? origin;
  final TripStop? destination;
  final bool cancelled;

  Trip({
    required this.tripId,
    required this.stop,
    this.when,
    this.plannedWhen,
    this.prognosedWhen,
    this.delay,
    this.platform,
    this.plannedPlatform,
    this.prognosedPlatform,
    this.prognosisType,
    this.direction,
    this.provenance,
    required this.line,
    required this.remarks,
    this.origin,
    this.destination,
    required this.cancelled,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    List<Remark> remarksList = [];
    if (json['remarks'] != null) {
      remarksList = (json['remarks'] as List)
          .map((remarkJson) => Remark.fromJson(remarkJson))
          .toList();
    }

    return Trip(
      tripId: json['tripId'],
      stop: TripStop.fromJson(json['stop']),
      when: json['when'],
      plannedWhen: json['plannedWhen'],
      prognosedWhen: json['prognosedWhen'],
      delay: json['delay'],
      platform: json['platform'],
      plannedPlatform: json['plannedPlatform'],
      prognosedPlatform: json['prognosedPlatform'],
      prognosisType: json['prognosisType'],
      direction: json['direction'],
      provenance: json['provenance'],
      line: Line.fromJson(json['line']),
      remarks: remarksList,
      origin: json['origin'] != null ? TripStop.fromJson(json['origin']) : null,
      destination: json['destination'] != null ? TripStop.fromJson(json['destination']) : null,
      cancelled: json['cancelled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'stop': stop.toJson(),
      'when': when,
      'plannedWhen': plannedWhen,
      'prognosedWhen': prognosedWhen,
      'delay': delay,
      'platform': platform,
      'plannedPlatform': plannedPlatform,
      'prognosedPlatform': prognosedPlatform,
      'prognosisType': prognosisType,
      'direction': direction,
      'provenance': provenance,
      'line': line.toJson(),
      'remarks': remarks.map((remark) => remark.toJson()).toList(),
      'origin': origin?.toJson(),
      'destination': destination?.toJson(),
      'cancelled': cancelled,
    };
  }

  DateTime? getPlannedDateTime() {
    return plannedWhen != null ? DateTime.parse(plannedWhen!) : null;
  }

  DateTime? getActualDateTime() {
    return when != null ? DateTime.parse(when!) : null;
  }
}

class Remark {
  final String? id;
  final String type;
  final String? summary;
  final String? text;
  final RemarkIcon? icon;
  final int? priority;
  final Products? products;
  final String? company;
  final List<int>? categories;
  final String? validFrom;
  final String? validUntil;
  final String? modified;
  final String? code;

  Remark({
    this.id,
    required this.type,
    this.summary,
    this.text,
    this.icon,
    this.priority,
    this.products,
    this.company,
    this.categories,
    this.validFrom,
    this.validUntil,
    this.modified,
    this.code,
  });

  factory Remark.fromJson(Map<String, dynamic> json) {
    List<int>? categoriesList;
    if (json['categories'] != null) {
      categoriesList = (json['categories'] as List).map((e) => e as int).toList();
    }

    return Remark(
      id: json['id'],
      type: json['type'],
      summary: json['summary'],
      text: json['text'],
      icon: json['icon'] != null ? RemarkIcon.fromJson(json['icon']) : null,
      priority: json['priority'],
      products: json['products'] != null ? Products.fromJson(json['products']) : null,
      company: json['company'],
      categories: categoriesList,
      validFrom: json['validFrom'],
      validUntil: json['validUntil'],
      modified: json['modified'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'summary': summary,
      'text': text,
      'icon': icon?.toJson(),
      'priority': priority,
      'products': products?.toJson(),
      'company': company,
      'categories': categories,
      'validFrom': validFrom,
      'validUntil': validUntil,
      'modified': modified,
      'code': code,
    };
  }
}

class RemarkIcon {
  final String type;
  final String? title;

  RemarkIcon({
    required this.type,
    this.title,
  });

  factory RemarkIcon.fromJson(Map<String, dynamic> json) {
    return RemarkIcon(
      type: json['type'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
    };
  }
}

class Operator {
  final String type;
  final String id;
  final String name;

  Operator({
    required this.type,
    required this.id,
    required this.name,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      type: json['type'],
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
    };
  }
}

class LineWithOperator extends Line {
  final Operator? operator;

  LineWithOperator({
    required super.type,
    required super.id,
    super.fahrtNr,
    required super.name,
    required super.public,
    required super.productName,
    required super.mode,
    required super.product,
    this.operator,
    String? adminCode,
  });

  factory LineWithOperator.fromJson(Map<String, dynamic> json) {
    return LineWithOperator(
      type: json['type'],
      id: json['id'],
      fahrtNr: json['fahrtNr'],
      name: json['name'],
      public: json['public'],
      productName: json['productName'],
      mode: json['mode'],
      product: json['product'],
      adminCode: json['adminCode'],
      operator: json['operator'] != null ? Operator.fromJson(json['operator']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['operator'] = operator?.toJson();
    return data;
  }
}

class TransitStop {
  final String type;
  final String id;
  final String name;
  final Location location;
  final Products products;
  final List<Line> lines;
  final int distance;

  TransitStop({
    required this.type,
    required this.id,
    required this.name,
    required this.location,
    required this.products,
    required this.lines,
    required this.distance,
  });

  factory TransitStop.fromJson(Map<String, dynamic> json) {
    // Handle case where lines might be null
    var linesJson = json['lines'];
    List<Line> linesList = [];

    if (linesJson != null) {
      linesList =
          (linesJson as List)
              .map((lineJson) => Line.fromJson(lineJson))
              .toList();
    }

    return TransitStop(
      type: json['type'],
      id: json['id'],
      name: json['name'],
      location: Location.fromJson(json['location']),
      products: Products.fromJson(json['products']),
      lines: linesList,
      distance: json['distance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'location': location.toJson(),
      'products': products.toJson(),
      'lines': lines.map((line) => line.toJson()).toList(),
      'distance': distance,
    };
  }
}

class TripStop {
  final String type;
  final String id;
  final String name;
  final Location location;
  final Products products;
  final List<Line>? lines; // Making lines optional

  TripStop({
    required this.type,
    required this.id,
    required this.name,
    required this.location,
    required this.products,
    this.lines,
  });

  factory TripStop.fromJson(Map<String, dynamic> json) {
    // Handle case where lines might be null
    List<Line>? linesList;
    if (json['lines'] != null) {
      linesList = (json['lines'] as List)
          .map((lineJson) => Line.fromJson(lineJson))
          .toList();
    }

    return TripStop(
      type: json['type'],
      id: json['id'],
      name: json['name'],
      location: Location.fromJson(json['location']),
      products: Products.fromJson(json['products']),
      lines: linesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'location': location.toJson(),
      'products': products.toJson(),
      'lines': lines?.map((line) => line.toJson()).toList(),
    };
  }
}

class Location {
  final String type;
  final String id;
  final double latitude;
  final double longitude;

  Location({
    required this.type,
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Products {
  final bool suburban;
  final bool subway;
  final bool tram;
  final bool bus;
  final bool ferry;
  final bool express;
  final bool regional;

  Products({
    required this.suburban,
    required this.subway,
    required this.tram,
    required this.bus,
    required this.ferry,
    required this.express,
    required this.regional,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      suburban: json['suburban'],
      subway: json['subway'],
      tram: json['tram'],
      bus: json['bus'],
      ferry: json['ferry'],
      express: json['express'],
      regional: json['regional'],
    );
  }

  Map<String, String> toMap() {
    Map<String, String> map = {};
    if (suburban) {
      map["suburban"] = "S-Bahn";
    }
    if (subway) {
      map["subway"] = "U-Bahn";
    }
    if (tram) {
      map["tram"] = "Tram";
    }
    if (bus) {
      map["bus"] = "Bus";
    }
    if (ferry) {
      map["ferry"] = "Fähre";
    }
    if (express) {
      map["express"] = "Express";
    }
    if (regional) {
      map["regional"] = "Regional";
    }
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'suburban': suburban,
      'subway': subway,
      'tram': tram,
      'bus': bus,
      'ferry': ferry,
      'express': express,
      'regional': regional,
    };
  }
}

class Line {
  final String type;
  final String id;
  final String? fahrtNr;
  final String name;
  final bool public;
  final String productName;
  final String mode;
  final String product;

  Line({
    required this.type,
    required this.id,
    this.fahrtNr,
    required this.name,
    required this.public,
    required this.productName,
    required this.mode,
    required this.product,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      type: json['type'],
      id: json['id'],
      fahrtNr: json['fahrtNr'],
      name: json['name'],
      public: json['public'],
      productName: json['productName'],
      mode: json['mode'],
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'fahrtNr': fahrtNr,
      'name': name,
      'public': public,
      'productName': productName,
      'mode': mode,
      'product': product,
    };
  }
}
