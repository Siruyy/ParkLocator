export class CreateLevelDto {
  levelNumber: number;
  name: string;
  totalCapacity: number;
}

export class UpdateLevelDto {
  levelNumber?: number;
  name?: string;
  totalCapacity?: number;
  isActive?: boolean;
}

export class LevelResponseDto {
  id: string;
  levelNumber: number;
  name: string;
  totalCapacity: number;
  availableSpots: number;
  isActive: boolean;
  venueId: string;
  createdAt: string;
  updatedAt: string;
}

export class LevelAvailabilityDto {
  id: string;
  levelNumber: number;
  name: string;
  totalCapacity: number;
  availableSpots: number;
  occupancyPercent: number;
}
