module utils;

import spasm.bindings.html : WebSocket;
import std.traits;
import spasm.rt.array;

@safe:
nothrow:

void send(T)(WebSocket* socket, string valueId, auto ref T t) {
  static if (is(T == bool)) {
    socket.send(text(`{"id":"`,valueId,`", "value": `, t, `}`));
  } else
    static assert("Not implemented yet for type "~T.stringof);
}

auto to(T)(string str) if (isIntegral!T) {
  T t = 0;
  for(size_t pos = 0; pos < str.length; pos++) {
    if (str[pos] < '0' || str[pos] > '9')
      continue;
    t *= 10;
    t += str[pos] - '0';
  }
  return t;
 }

auto to(T)(string str) if (isFloatingPoint!T) {
  double d = str.StringToDouble();
  return cast(T)d;
 }

extern(C) double StringToDouble(string);
