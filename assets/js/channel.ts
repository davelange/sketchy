import { Socket } from 'phoenix';

export function joinChannel({
	id,
}: {
	id: string;	
}) {
	const socket = new Socket("/socket");
	socket.connect();

	const channel = socket.channel(`game:${id}`);

	channel
		.join()
		.receive('ok', (data) => {
			console.log('Joined successfully', data);
		})
		.receive('error', (resp) => {
			console.log('Unable to join', resp);
		});
	
}
