package haxe.remoting;

@:genericBuild(haxe.remoting.ProxyBuilder.build())
class Proxy<T> {

	var __cnx : Connection;

	function new( c ) {
		__cnx = c;
	}

}
