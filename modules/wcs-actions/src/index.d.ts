import { SystemTable } from "@rbxts/cake";
import type {
	ServerSystemProps,
	ClientSystemProps,
} from "@rbxts/wcs-actions";

declare namespace CakeWCSActions {
	export const initialize_server: SystemTable<[ServerSystemProps<any>]>;
	export const initialize_client: SystemTable<[ClientSystemProps<any>]>;
}

export = CakeWCSActions;
