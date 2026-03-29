import { SystemTable, SystemContext } from "@rbxts/cake";
import { Server, Client } from "@rbxts/replecs";

declare namespace CakeReplecs {
	interface ServerEventLike<T extends unknown[] = []> {
		readonly OnServerEvent: RBXScriptSignal<(player: Player, ...args: T) => void>;
		FireClient(this: ServerEventLike<T>, player: Player, ...args: T): void;
	}

	interface ClientEventLike<T extends unknown[] = []> {
		readonly OnClientEvent: RBXScriptSignal<(...args: T) => void>;
		FireServer(this: ClientEventLike<T>, ...args: T): void;
	}

	interface ServerRemotes {
		readonly request_full: ServerEventLike;
		readonly send_full: ServerEventLike<[buffer, defined[][]?]>;
		readonly send_unreliables: ServerEventLike<[buffer, defined[][]?]>;
		readonly send_updates: ServerEventLike<[buffer, defined[][]?]>;
	}

	interface ClientRemotes {
		readonly request_full: ClientEventLike;
		readonly send_full: ClientEventLike<[buffer, defined[][]?]>;
		readonly send_unreliables: ClientEventLike<[buffer, defined[][]?]>;
		readonly send_updates: ClientEventLike<[buffer, defined[][]?]>;
	}

	export const initialize_server: SystemTable<[Server, ServerRemotes, SystemContext]>;
	export const initialize_client: SystemTable<[Client, ClientRemotes, SystemContext]>;
}

export = CakeReplecs;
