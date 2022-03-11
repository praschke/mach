const Texture = @This();

/// The type erased pointer to the Texture implementation
/// Equal to c.WGPUTexture for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor);
    destroy: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(texture: Texture) void {
    texture.vtable.reference(texture.ptr);
}

pub inline fn release(texture: Texture) void {
    texture.vtable.release(texture.ptr);
}

pub inline fn setLabel(texture: Texture, label: [:0]const u8) void {
    texture.vtable.setLabel(texture.ptr, label);
}

pub inline fn destroy(texture: Texture) void {
    texture.vtable.destroy(texture.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = destroy;
}