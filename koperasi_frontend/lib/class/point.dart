class Point {

  final int point;

  Point({
    required this.point
  });

  factory Point.fromJson(Map<String, dynamic> json){
    return Point(
      point: json['point']
    );
  }

}