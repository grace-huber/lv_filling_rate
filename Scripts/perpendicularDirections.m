function [firstPerpendicular, secondPerpendicular] = perpendicularDirections(longAxisDirection)

heightDirection = [0 1 0];
firstPerpendicular = heightDirection - dot(heightDirection, longAxisDirection) * longAxisDirection;
firstPerpendicular = firstPerpendicular / norm(firstPerpendicular);
secondPerpendicular = cross(firstPerpendicular, longAxisDirection);
end
