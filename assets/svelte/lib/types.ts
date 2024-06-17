export type Player = {
  id: string;
  name: string;
  team: string;
};

export type Team = {
  id: string;
  name: string;
  score: number;
  word_guessed: false;
  active_user_id: string;
};

export type Point = [x: number, y: number, clicked: number];

export enum PointAccess {
  x = 0,
  y = 1,
  clicked = 2,
}

export type Shape = {
  points: Point[];
  id?: string;
  idx?: number;
};

export type GameStatus =
  | "pending"
  | "turn_pending"
  | "turn_ongoing"
  | "turn_over"
  | "done";

export type GameState = {
  shapes: Shape[];
  players: Player[];
  teams: Team[];
  active_user_id: string;
  state: GameStatus;
  turn_duration: number;
  remaining_in_turn: number;
  round: number;
};

export type OnJoinData = GameState & {
  self: Player;
};

export type OnShapesUpdated = { shapes: Shape[]; player: string };

export type OnUserGuess = { user: Player; value: string; correct: boolean };

export type TurnAction = "start" | "start_turn";
