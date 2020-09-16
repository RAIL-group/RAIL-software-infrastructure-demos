#include <math.h>

#pragma once

// Defines the Pose class
static int pose_count;

struct Pose {
 protected:
  static int class_id;
 public:
  int index;
  double x, y, yaw;

  Pose(double xi, double yi, double yawi): x(xi), y(yi),  yaw(yawi) {
    index = ++class_id;
  }

  Pose mul(const Pose &oth) const {
    return oth.rmul(*this);
  }

  Pose rmul(const Pose &oth) const;

  static Pose get_odom(const Pose &p_new, const Pose &p_old);

  Pose operator* (const Pose &oth) const {
    return mul(oth);
  }

};
