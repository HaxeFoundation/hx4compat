package haxe.remoting;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class ProxyBuilder {
	static public function build() {
		var p = Context.currentPos();
		var t = Context.getLocalType();
		var c = switch (t) {
			case TInst(_, [t]):
				var acc = [];
				switch (t) {
					case TInst(_.get() => c, _):
						c;
					case _:
						Context.error("Unexpected type: " + t, p);
				}
			case _:
				Context.error("Unexpected type: " + t, p);
		}
		var name = 'Remoting_${c.name}';
		var fullName = c.pack.concat([name]).join(".");
		try {
			return Context.getType(fullName).toComplexType();
		} catch (_:String) {
			var isPublic = c.isExtern || c.isInterface;
			var td = macro class $name {
				public function new(c:haxe.remoting.Connection) {
					this.__cnx = c;
				}

				var __cnx:haxe.remoting.Connection;
			};
			td.pack = c.pack;
			for (field in c.fields.get()) {
				if (!isPublic && !field.isPublic) {
					continue;
				}
				switch (field.kind) {
					case FVar(_, _):
						continue;
					case FMethod(_):
				}
				switch (field.type.follow()) {
					case TFun(args, ret):
						var idents = args.map(arg -> arg.name);
						var fArgs = args.map(arg -> {
							name: arg.name,
							type: arg.t.toComplexType(),
							meta: [],
							opt: false,
							value: null
						});
						var args = args.map(arg -> macro $i{arg.name});

						var args = macro $a{args};
						var expr = macro __cnx.resolve($v{field.name}).call($args);
						if (ret.toString() != "Void") {
							expr = macro return $expr;
						}
						var field = {
							name: field.name,
							kind: FFun({
								args: fArgs,
								expr: expr,
								ret: ret.toComplexType()
							}),
							pos: p,
							access: [APublic]
						}
						td.fields.push(field);
					case _:
						continue;
				}
			}

			Context.defineType(td);
			return TPath({pack: td.pack, name: td.name});
		}
	}
}
