export type User = {
  id: string;
  name: string;
  points: number;
};

export type Point = [
  x: number,
  y: number,
  clicked: number
];

export enum PointAccess {
  x = 0,
  y = 1,
  clicked = 2,
}

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
  active_user_id: string;
  status: GameStatus;
  turn_duration: number;
  remaining_in_turn: number;
  round: number;
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
