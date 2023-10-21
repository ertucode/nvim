import { CommonModule } from "@angular/common"
import { Component, Input } from "@angular/core"
import { LocalizationModule } from "@sipaywalletgate/ngx-sipay/localization"

@Component({
  selector: "hello-world",
  imports: [LocalizationModule, CommonModule],
  styleUrls: ["./hello-world.component.scss"],
  templateUrl: "./hello-world.component.html",
  standalone: true,
})
export class HelloWorldComponent {
  @Input() input: string

  constructor() {}
}
