import { SystemTable, SystemContext } from "@rbxts/cake";
import { Server, Client } from "@rbxts/replecs";

declare namespace CakeReplecs {
	export const initialize_server: SystemTable<[Server, SystemContext]>;
	export const initialize_client: SystemTable<[Client, SystemContext]>;
}

export = CakeReplecs;
