export class CreateVenueDto {
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  description?: string;
  imageUrl?: string;
}

export class UpdateVenueDto {
  name?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  description?: string;
  imageUrl?: string;
  isActive?: boolean;
}

export class VenueResponseDto {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  description: string | null;
  imageUrl: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export class NearbyVenueDto extends VenueResponseDto {
  distance: number; // Distance in meters
  levelsCount: number;
  totalCapacity: number;
  availableSpots: number;
}

export class FindNearbyDto {
  lat: number;
  lng: number;
  radius?: number; // in kilometers, default 5
}
