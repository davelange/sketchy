export type User = {
  id: string;
  name: string;
  points: number;
};

export type Point = {
  x: number;
  y: number;
  clicked: boolean;
};

export type Shape = {
  points: Point[];
  closed?: boolean;
  id?: number;
};

export type GameStatus =
  | "pending"
  | "turn_pending"
  | "turn_ongoing"
  | "turn_over"
  | "done";

export type GameState = {
  shapes: Shape[];
  users: User[];
  active_user: User;
  status: GameStatus;
  turn_duration: number;
  remaining_in_turn: number;
};

export type OnJoinData = GameState & {
  self: User;
};

export type OnUserJoinedData = User;

export type OnNewData = {
  shapes: Shape[];
};

export type OnUserGuess = { user: User; value: string; correct: boolean };

export type TurnAction = "start" | "start_turn";
