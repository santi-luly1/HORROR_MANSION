// --<<SERVER>>--
import Default from "./Default";

export default class Flashlight extends Default {
	public Setup(): void {
		const handle = this.tool.FindFirstChild("Handle") as Part;
		const spotLight = handle.FindFirstChild("SpotLight") as SpotLight;

		const sound = new Instance("Sound");
		sound.SoundId = "rbxassetid://115959318";
		sound.Volume = 1;
		sound.Parent = handle;

		this.trove.add(
			this.tool.Activated.Connect(() => {
				spotLight.Enabled = !spotLight.Enabled;
				sound.Play();
			}),
		);
	}
}
