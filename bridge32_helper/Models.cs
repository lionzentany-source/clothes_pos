using System.Text.Json.Serialization;

internal record OutEvent(
    [property: JsonPropertyName("event")] string Event,
    [property: JsonPropertyName("epc")] string? Epc = null,
    [property: JsonPropertyName("message")] string? Message = null
);

internal record InCommand(
    [property: JsonPropertyName("cmd")] string Cmd
);
