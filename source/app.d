import ldc.attributes;

import spasm.types;
import spasm.spa;
import spasm.rt.array;
import spasm.rt.memory;
import spasm.bindings.html;
import spasm.dom;
import spasm.css;
import spasm.sumtype;
import spasm.bindings.console;
import openzwave;
import std.traits;
import std.meta;
import utils;
import std.algorithm;
import std.range;
import std.functional : forward;

@safe:
nothrow:

version (unittest) {
} else
    mixin Spa!App;

struct ItemStyles {
  struct table {
    auto border = "1px solid black";
  }
  struct row {
    auto background = "#efefef";
    @("nth-child(odd)") struct alternate {
      auto background = "#d2d2d2";
    }
  }
  struct cell {
    auto borderSpacing = "0px";
    auto padding = "0";
  }
  struct cellheader {
    auto textAlign = "right";
    auto paddingRight = "10px";
  }
  struct item {
    auto display = "flex";
    auto flexDirection = "row";
  }
}

struct BoolValue {
  nothrow:
  mixin Node!"input";
  mixin Slot!"change";
  @attr string type() { return "checkbox"; }
  @attr string name;
  @prop bool checked = false;
  @callback void onChange(Event event) {
    checked = node.checked;
    this.emit(change);
  }
  bool content() {
    return checked;
  }
  void content(bool value) {
    this.update.checked = value;
  }
}

struct IntValue {
  nothrow:
  mixin Node!"input";
  mixin Slot!"change";
  @attr string type() { return "number"; }
  @attr string name;
  @prop int value = 0;
  @callback void onChange(Event event) {
    value = node.value.to!int;
    this.emit(change);
  }
  int content() {
    return value;
  }
  void content(int value) {
    this.update.value = value;
  }
}

struct DoubleValue {
  nothrow:
  mixin Node!"input";
  mixin Slot!"change";
  @attr string type() { return "number"; }
  @attr string name;
  @prop double value = 0;
  @callback void onChange(Event event) {
    value = node.value.to!double;
    this.emit(change);
  }
  double content() {
    return value;
  }
  void content(double value_) {
    this.update.value = value_;
  }
}

struct UnknownValue {
  nothrow:
  mixin Slot!"change";
  string value;
  string content() {
    return value;
  }
  void content(string value) {
    this.value = value;
  }
}

@styleset!(ItemStyles)
struct ValueHeader {
  @style!"cell" @style!"cellheader" mixin Node!"td";
  @prop string textContent;
}

@styleset!(ItemStyles)
struct ValueContent(Component) {
  @style!"cell" mixin Node!"td";
  @child Component component;
  alias component this;
}

@styleset!(ItemStyles)
struct ValueItem(Component) {
  nothrow:
  alias ValueType = ReturnType!(Component.content);
  @style!"row" mixin Node!"tr";
  @child ValueHeader header;
  @child ValueContent!Component component;
  string valueId;
  WebSocket* socket;
  this(ref ZWaveValue value, WebSocket* socket) {
    header.textContent = value.label;
    valueId = value.id;
    this.socket = socket;
    component.content(value.get!ValueType);
  }
  @connect!"component.change" void onChange() {
    send(socket, valueId, component.content);
  }
  void onValue(ref ZWaveValue zwaveValue) @trusted {
    component.content(zwaveValue.get!ValueType);
  }
}

auto makeValue(Allocator, Args...)(auto ref Allocator allocator, openzwave.ValueType type, Args args) {
  auto makeIt(T)() {
    return allocator.make!(Value)(ValueItem!T(args));
  }
  switch (type) {
  case openzwave.ValueType.Bool: return makeIt!(BoolValue);
  case openzwave.ValueType.Int: return makeIt!(IntValue);
  case openzwave.ValueType.Byte: return makeIt!(IntValue);
  case openzwave.ValueType.Short: return makeIt!(IntValue);
  case openzwave.ValueType.Decimal: return makeIt!(DoubleValue);
  default:
    return makeIt!(UnknownValue);
  }
}

template skipUntil(alias fun) {
  auto skipUntil(Range)(Range range) { // if (is(ElementType!Range == Value)) {
    return range.find!(i => spasm.sumtype.match!(fun)(*i));
  }
}

template match(alias fun) {
  // NOTE: Why the hell is this @trusted?
  auto match(Range)(auto ref Range range) @trusted { // if (is(ElementType!Range == Value)) {
    foreach(ref i; range)
      spasm.sumtype.match!(fun)(*i);
  }
}

template matchFirst(alias fun) {
  auto matchFirst(Range)(auto ref Range range) { // if (is(ElementType!Range == Value)) {
    range.take(1).match!(fun);
  }
}

struct NodeHeader {
  @style!"text-black" @style!"text-lg" @style!"font-bold" mixin Node!"div";
  @prop string textContent;
}

// @styleset!(ItemStyles)
struct NodeItem {
  nothrow:
  @style!"m-4" @style!"bg-white" @style!"rounded" @style!"shadow-lg" @style!"p-4" mixin Node!"div";
  @child NodeHeader header;
  @style!"w-full" @child List!(Value,"table") list;
  ZWaveNode* zwaveNode;
  WebSocket* socket;
  this(ZWaveNode* zwaveNode, WebSocket* socket) {
    this.zwaveNode = zwaveNode;
    this.socket = socket;
    header.textContent = zwaveNode.productName;
  }
  void onValueAdded(ref ZWaveValue zwaveValue) @trusted {
    auto rest = list.items[].skipUntil!((scope ref i) => i.valueId == zwaveValue.id);
    if (rest.empty) {
      list.put(allocator.makeValue(zwaveValue.type, zwaveValue, socket));
      list.update();
    } else {
      foreach(i; rest.take(1))
        spasm.sumtype.match!(
                             (scope ref i) => i.onValue(zwaveValue)
                             )(*i);
    }
    // rest.take(1).each!(i => spasm.sumtype.match!((scope ref ValueItem!BoolValue i) => (scope ref i) @safe => i.onValue(zwaveValue))(*i));
  }
  void onValueChanged(ref ZWaveValue zwaveValue) @trusted {
    list.items[].skipUntil!((scope ref i) => i.valueId == zwaveValue.id).take(1).match!((scope ref i) => i.onValue(zwaveValue));
  }
private:
}

alias Value = SumType!(ValueItem!BoolValue, ValueItem!IntValue, ValueItem!DoubleValue, ValueItem!UnknownValue);

struct Tabs(Ts...) {

}

template notifyChildren(string name) {
  auto notifyChildren(Parent, Args...)(ref Parent parent, auto ref Args args) {
    alias children = getChildren!Parent;
    static foreach(childName; children) {{
        alias childSymbol = __traits(getMember, parent, childName);
        alias Child = typeof(childSymbol);
        static if (hasMember!(Child, name)) {
          alias childMember = __traits(getMember, childSymbol, name);
          __traits(getMember, __traits(getMember, parent, childName), name)(forward!args);
        } else {
          .notifyChildren!(name)(__traits(getMember, parent, childName), forward!args);
        }
      }}
  }
}

struct App {
  nothrow:
  @style!"bg-gray-100" @style!"min-h-full" mixin Node!"div";
  // @child Omnibox omnibox;
  @(param.socket!socket)
  @child DevicesTab devicesTab;
  WebSocket socket;
  void onMount() {
    import std.algorithm;
    auto protocols = SumType!(string, Sequence!(string))(Sequence!(string)());
    socket = window().WebSocket("ws://permanence.home:8080/events", protocols);
    socket.onmessage!()(&onMessage);
  }
  Any onMessage(spasm.bindings.dom.Event event) @trusted {
    Any data = event.as!MessageEvent.data;
    auto message = Json(JSON_parse(*data.ptr));
    auto msgType = message.message.as!string;
    if (msgType == "value-added") {
      auto value = message.value;
      auto zwaveValue = readJson!(ZWaveValue)(value);
      this.notifyChildren!"onValueAdded"(zwaveValue);
    } else if (msgType == "node-added") {
      auto node = message.node;
      auto zwaveNode = readJson!(ZWaveNode*)(node);
      this.notifyChildren!"onNodeAdded"(zwaveNode);
    } else if (msgType == "value-changed") {
      auto value = message.value;
      auto zwaveValue = readJson!(ZWaveValue)(value);
      this.notifyChildren!"onValueChanged"(zwaveValue);
    }
    return Any(0);
  }
}

struct OmniboxStyles {
  struct root {
    auto width = "300px";
    auto position = "relative";
  }
  struct container {
    auto position = "absolute";
    auto display = "block";
    auto width = "100%";
    auto height = "109px";
    auto overflowY = "scroll";
    auto border = "1px solid gray";
    auto boxShadow = "3px 3px 7px grey";
  }
  struct list {
    auto listStyleType = "none";
    auto margin = "0";
    auto padding = "0";
    auto background = "#ffffff";
    auto width = "100%";
  }
  struct item {
    auto padding = "5px 10px";
    @("hover") struct hover {
      auto backgroundColor = "#a3eaff";
    }
  }
}

@styleset!OmniboxStyles
struct Omnibox {
  nothrow:
  @styleset!OmniboxStyles
  struct Option {
    nothrow:
    @style!"item" mixin Node!"li";
    mixin Slot!"clicked";
    @prop string textContent;
    string id;
    this(ref ZWaveValue value) {
      textContent = value.label;
      id = value.id;
    }
    @callback onMousedown(MouseEvent event) {
      this.emit(clicked);
    }
  }

  @style!"root" mixin Node!"div";
  @style!"input" @child Input input;
  @(param.values!options.query!query)
  @style!"container" @child Suggestions suggestions;

  @visible!"suggestions" bool open = true;

  string query;
  ZWaveNodeList nodes;
  DynamicArray!(Option*) options;

  void onNodeAdded(ZWaveNode* node) {
    nodes.put(node);
  }
  void onValueAdded(ref ZWaveValue value) {
    options.put(getAllocator.make!(Omnibox.Option)(value));
    this.update!options;
  }

  @connect!"input.change" auto onChange() {
    this.update.query = input.value;
  }

  @connect!"input.focus" auto onFocus() {
    this.update.open = true;
  }

  @connect!"input.blur" auto onBlur() {
    this.update.open = false;
  }

  @connect!("suggestions.options.items","clicked") void onAdd(size_t idx) {
    console.log(suggestions.options.items[idx].id);
  }

  struct Input {
    nothrow:
    mixin Node!"input";
    mixin Slot!"focus";
    mixin Slot!"blur";
    mixin Slot!"change";
    @prop string value;
    @callback onFocus(FocusEvent event) { this.emit(focus); }
    @callback onBlur(Event event) { this.emit(blur); }
    @callback onInput(InputEvent event) {
      value = node.value;
      this.emit(change);
    }
  }

  @styleset!OmniboxStyles
  struct Suggestions {
    nothrow:
    mixin Node!"div";
    @style!"list" @child List!(Option,"ul") options;
    DynamicArray!(Option*)* values;
    string* query;
    void transform(DynamicArray!(Option*)* values, string* query) {
      // it is hard to determine if query is changed or not
      // e.g. in a virtual list we only care about the first 20 items, and we should only update when query is changed (not when the 23rd element is added)
      (*values)[].filter!((o){return o.textContent.contains(*query);}).take(10).update(options);
    }

  }

}

bool contains(string haystack, string needle) {
  if (needle.length == 0)
    return true;
  if (needle.length > haystack.length)
    return false;
  if (haystack.length == 0)
    return false;
  size_t hpos, npos;
  size_t end = haystack.length - needle.length;
  while (hpos <= end) {
    npos = 0;
    while (needle[npos] == haystack[hpos+npos]) {
      npos++;
      if (npos == needle.length)
        return true;
    }
    hpos++;
  }
  return false;
}

unittest {
  assert( contains("abc","abc"));
  assert(!contains("","abc"));
  assert( contains("abc",""));
  assert( contains("defghijabc","abc"));
}

alias ZWaveNodeList = DynamicArray!(ZWaveNode*);

auto getAllocator() @trusted {
  return allocator;
}

enum receiverNode = "16817852562488164000";

// @styleset!(ItemStyles)
struct DevicesTab {
  nothrow:
  @style!"flex" @child List!(NodeItem,"div") list;
  WebSocket* socket;
  void onNodeAdded(ZWaveNode* node) {
    console.log(node.productName);
    if (node.productName != "EUR_SPIRITZ Wall Radiator Thermostat" &&
        node.productName != "SSR 303 Thermostat Receiver")
      return;
    if (!list.items[].canFind!(i => i.zwaveNode.nodeId == node.nodeId))
      list.put(getAllocator.make!(NodeItem)(node, socket));
  }
  void onValueAdded(ref ZWaveValue value) {
    // if (value.id != "47865462784")
    //   return;
    if (value.label != "Air Temperature" && value.label != "Switch")
      return;
    list.items[]
      .find!(i => i.zwaveNode.nodeId == value.nodeId)
      .take(1)
      .each!(i => i.onValueAdded(value));
  }
  void onValueChanged(ref ZWaveValue value) {
    list.items[]
      .find!(i => i.zwaveNode.nodeId == value.nodeId)
      .take(1)
      .each!(i => i.onValueChanged(value));
  }
}

auto readJson(T)(scope ref Json json) @trusted {
  import spasm.rt.memory;
  import std.traits;
  template getBaseType(T) {
    static if (is(T == enum))
      alias getBaseType = OriginalType!T;
    else
      alias getBaseType = T;
  }
  static if (isPointer!T) {
    T t = allocator.make!(PointerTarget!(T));
    alias Target = PointerTarget!T;
  } else {
    T t;
    alias Target = T;
  }
  foreach(idx, field; t.tupleof) {
    t.tupleof[idx] = cast(typeof(field))json.opDispatch!(__traits(identifier, Target.tupleof[idx])).as!(getBaseType!(typeof(field)));
  }
  return t;
}

extern(C) {
  Handle JSON_parse(Handle);
}
