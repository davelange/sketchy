export function throttle<T = void>(fn: (args: T) => void, interval: number) {
	let enabled = true;
	let debounceTimeout: ReturnType<typeof setTimeout>;

	function startTimer() {
		enabled = false;
		setTimeout(() => (enabled = true), interval);
	}

	return (args: T) => {
		clearTimeout(debounceTimeout);

		debounceTimeout = setTimeout(() => fn(args), interval);

		if (enabled) {
			startTimer();
			fn(args);
		}
	};
}
