export interface GameSystem {
  id: string;
  name: string;
  description: string | null;
  logo_image_url: string | null;
  video_url?: string | null;
  type?: string | null;
  status?: string | null;
  order?: number;
  type_id?: string;
}