enum PlatformType {
  normal,
  moving,
  spring,
  fragile,
}

enum CollectibleType {
  star,
  musicNote,
  guitarPick,
  drink,
  batagor,
  coffee,
}

enum EnemyType {
  bird,
  ghost,
}

class GamePlatform {
  double x;
  double y;
  double width;
  double height;
  final PlatformType type;
  bool isBroken;
  double speed;
  int direction; // 1 = right, -1 = left
  CollectibleType? collectible;

  GamePlatform({
    required this.x,
    required this.y,
    this.width = 65,
    this.height = 14,
    this.type = PlatformType.normal,
    this.isBroken = false,
    this.speed = 1.5,
    this.direction = 1,
    this.collectible,
  });
}

class GameEnemy {
  double x;
  double y;
  double width;
  double height;
  final EnemyType type;
  int direction; // 1 = right, -1 = left
  double speed;
  int animFrame;
  double animTimer;

  GameEnemy({
    required this.x,
    required this.y,
    this.width = 38,
    this.height = 32,
    this.type = EnemyType.bird,
    this.direction = 1,
    this.speed = 1.8,
    this.animFrame = 0,
    this.animTimer = 0,
  });
}

class JumperPlayer {
  double x;
  double y;
  double width;
  double height;
  double velX;
  double velY;
  bool facingRight;

  JumperPlayer({
    required this.x,
    required this.y,
    this.width = 44,
    this.height = 48,
    this.velX = 0,
    this.velY = 0,
    this.facingRight = true,
  });

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    velX = 0;
    velY = -12;
    facingRight = true;
  }
}
