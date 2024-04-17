import { Socket } from 'phoenix';
import type {
	GameState,
	OnJoinData,
	OnNewData,
	OnUserGuess,
	OnUserJoinedData,
	Shape,
	User
} from './types';

type EventCallback<T> = (data: T) => void;

export function joinChannel({
	id,
	userName,
	onJoin,
	onUserJoined,
	onShapesUpdated,
	onTurnUpdate,
	onUserGuess
}: {
	id: string;
	userName: string;
	onJoin: EventCallback<OnJoinData>;
	onUserJoined: EventCallback<OnUserJoinedData>;
	onShapesUpdated: EventCallback<OnNewData>;
	onTurnUpdate: EventCallback<GameState>;
	onUserGuess: EventCallback<OnUserGuess>;
}) {
	let user: User;

	const socket = new Socket("/socket");
	socket.connect();

	const channel = socket.channel(`game:${id}`, { user: userName });

	channel
		.join()
		.receive('ok', (data: OnJoinData) => {
			console.log('Joined successfully', data);
			user = data.self;
			onJoin(data);
		})
		.receive('error', (resp) => {
			console.log('Unable to join', resp);
		});

	// Attach listeners
	channel.on('shapes_updated', onShapesUpdated);
	channel.on('user_joined', onUserJoined);
	channel.on('turn_update', onTurnUpdate);
	channel.on('user_guess', onUserGuess);

	// Client actions
	const updateShapes = (data: { shapes: Shape[] }) => {
		channel.push('user_action', {
			...data,
			action: 'update_shapes',
			user
		});
	};

	const startGame = () => {
		channel.push('user_action', {
			action: 'start',
			user
		});
	};

	const startTurn = ({ value }: { value: string }) => {
		channel.push('user_action', {
			action: 'start_turn',
			value,
			user
		});
	};

	const makeGuess = ({ value }: { value: string }) => {
		channel.push('user_action', {
			action: 'guess',
			value,
			user
		});
	};

	return {
		updateShapes,
		startGame,
		startTurn,
		makeGuess
	};
}
