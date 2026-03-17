import { SystemTable } from "@rbxts/cake";
import { Server, Client } from "@rbxts/replecs";

declare namespace CakeReplecs {
	interface ServerEventLike<T extends unknown[] = []> {
		readonly fire: (...args: T) => void;
		readonly collect: IterableFunction<LuaTuple<[number, Player, ...T]>>;
	}

	interface ClientEventLike<T extends unknown[] = []> {
		readonly fire: (player: Player, ...args: T) => void;
		readonly collect: IterableFunction<LuaTuple<[number, ...T]>>;
	}

	interface Remotes {
		readonly request_full: ServerEventLike;
		readonly send_full: ClientEventLike<[buffer, defined[][]?]>;
		readonly send_unreliables: ClientEventLike<[buffer, defined[][]?]>;
		readonly send_updates: ClientEventLike<[buffer, defined[][]?]>;
	}

	export const initialize_server: SystemTable<[Server, Remotes]>;
	export const initialize_client: SystemTable<[Client, Remotes]>;
}

export = CakeReplecs;
